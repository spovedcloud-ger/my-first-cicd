require('dotenv').config();
const express = require('express');
const { Pool } = require('pg');
const { createClient } = require('redis');
const promClient = require('prom-client');

const app = express();
const port = process.env.PORT || 3000;

// Prometheus metrics setup
const register = new promClient.Registry();

// Add default metrics (CPU, memory, event loop, etc.)
promClient.collectDefaultMetrics({ register });

// Custom metrics
const httpRequestDuration = new promClient.Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'status_code'],
  buckets: [0.01, 0.05, 0.1, 0.5, 1, 2, 5]
});

const httpRequestTotal = new promClient.Counter({
  name: 'http_requests_total',
  help: 'Total number of HTTP requests',
  labelNames: ['method', 'route', 'status_code']
});

const databaseQueryDuration = new promClient.Histogram({
  name: 'database_query_duration_seconds',
  help: 'Duration of database queries in seconds',
  labelNames: ['query_type', 'table'],
  buckets: [0.001, 0.005, 0.01, 0.05, 0.1, 0.5, 1]
});

const redisOperationDuration = new promClient.Histogram({
  name: 'redis_operation_duration_seconds',
  help: 'Duration of Redis operations in seconds',
  labelNames: ['operation', 'status'],
  buckets: [0.001, 0.005, 0.01, 0.05, 0.1, 0.5, 1]
});

register.registerMetric(httpRequestDuration);
register.registerMetric(httpRequestTotal);
register.registerMetric(databaseQueryDuration);
register.registerMetric(redisOperationDuration);

// Structured JSON Logger
const logger = {
  info: (message, meta = {}) => {
    console.log(JSON.stringify({ timestamp: new Date().toISOString(), level: 'info', message, ...meta }));
  },
  error: (message, meta = {}) => {
    console.error(JSON.stringify({ timestamp: new Date().toISOString(), level: 'error', message, ...meta }));
  }
};

// Middleware to track request metrics and log requests
app.use((req, res, next) => {
  const start = Date.now();
  res.on('finish', () => {
    const duration = (Date.now() - start) / 1000;
    const route = req.route ? req.route.path : req.path;
    
    // Metrics
    httpRequestDuration.labels(req.method, route, res.statusCode).observe(duration);
    httpRequestTotal.labels(req.method, route, res.statusCode).inc();
    
    // Structured Log
    logger.info('HTTP Request', {
      method: req.method,
      url: req.url,
      path: route,
      statusCode: res.statusCode,
      durationMs: duration * 1000
    });
  });
  next();
});

// PostgreSQL connection
const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5432,
  user: process.env.DB_USER || 'appuser',
  password: process.env.DB_PASSWORD || 'apppassword',
  database: process.env.DB_NAME || 'appdb',
});

// Redis client
const redisClient = createClient({
  socket: {
    host: process.env.REDIS_HOST || 'localhost',
    port: process.env.REDIS_PORT || 6379,
  },
});

redisClient.on('error', (err) => logger.error('Redis Client Error', { error: err.message }));

// Initialize connections
async function initializeConnections() {
  try {
    // Test PostgreSQL
    const pgResult = await pool.query('SELECT NOW()');
    logger.info('PostgreSQL connected', { time: pgResult.rows[0].now });

    // Connect Redis
    await redisClient.connect();
    logger.info('Redis connected');
  } catch (error) {
    logger.error('Connection error', { error: error.message });
  }
}

app.use(express.json());

// Prometheus metrics endpoint
app.get('/metrics', async (req, res) => {
  try {
    res.set('Content-Type', register.contentType);
    res.end(await register.metrics());
  } catch (error) {
    res.status(500).end(error.message);
  }
});

// Health check
app.get('/api/health', async (req, res) => {
  try {
    await pool.query('SELECT 1');
    await redisClient.ping();
    res.json({ 
      status: 'healthy',
      postgres: 'connected',
      redis: 'connected',
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    res.status(503).json({ 
      status: 'unhealthy',
      error: error.message 
    });
  }
});

// Get all users (cached)
app.get('/api/users', async (req, res) => {
  try {
    // Check cache first
    const cacheStart = Date.now();
    const cached = await redisClient.get('users:all');
    redisOperationDuration.labels('get', cached ? 'hit' : 'miss').observe((Date.now() - cacheStart) / 1000);
    
    if (cached) {
      return res.json({ 
        source: 'cache', 
        data: JSON.parse(cached) 
      });
    }

    // Fetch from database
    const dbStart = Date.now();
    const result = await pool.query('SELECT id, username, email, created_at FROM users ORDER BY created_at DESC');
    databaseQueryDuration.labels('SELECT', 'users').observe((Date.now() - dbStart) / 1000);
    
    // Store in cache (5 minutes)
    const cacheSetStart = Date.now();
    await redisClient.setEx('users:all', 300, JSON.stringify(result.rows));
    redisOperationDuration.labels('set', 'success').observe((Date.now() - cacheSetStart) / 1000);
    
    res.json({ 
      source: 'database', 
      data: result.rows 
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Create user
app.post('/api/users', async (req, res) => {
  try {
    const { username, email } = req.body;
    if (!username || !email) {
      return res.status(400).json({ error: 'Username and email required' });
    }

    const dbStart = Date.now();
    const result = await pool.query(
      'INSERT INTO users (username, email) VALUES ($1, $2) RETURNING *',
      [username, email]
    );
    databaseQueryDuration.labels('INSERT', 'users').observe((Date.now() - dbStart) / 1000);

    // Invalidate cache
    const cacheStart = Date.now();
    await redisClient.del('users:all');
    redisOperationDuration.labels('del', 'success').observe((Date.now() - cacheStart) / 1000);

    res.status(201).json({ 
      message: 'User created', 
      data: result.rows[0] 
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get user by ID
app.get('/api/users/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const cacheKey = `user:${id}`;
    
    // Check cache
    const cacheStart = Date.now();
    const cached = await redisClient.get(cacheKey);
    redisOperationDuration.labels('get', cached ? 'hit' : 'miss').observe((Date.now() - cacheStart) / 1000);
    
    if (cached) {
      return res.json({ 
        source: 'cache', 
        data: JSON.parse(cached) 
      });
    }

    // Fetch from database
    const dbStart = Date.now();
    const result = await pool.query('SELECT id, username, email, created_at FROM users WHERE id = $1', [id]);
    databaseQueryDuration.labels('SELECT', 'users').observe((Date.now() - dbStart) / 1000);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    // Store in cache (10 minutes)
    const cacheSetStart = Date.now();
    await redisClient.setEx(cacheKey, 600, JSON.stringify(result.rows[0]));
    redisOperationDuration.labels('set', 'success').observe((Date.now() - cacheSetStart) / 1000);
    
    res.json({ 
      source: 'database', 
      data: result.rows[0] 
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Delete user
app.delete('/api/users/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    const dbStart = Date.now();
    await pool.query('DELETE FROM users WHERE id = $1', [id]);
    databaseQueryDuration.labels('DELETE', 'users').observe((Date.now() - dbStart) / 1000);
    
    // Invalidate caches
    const cacheStart = Date.now();
    await redisClient.del('users:all');
    await redisClient.del(`user:${id}`);
    redisOperationDuration.labels('del', 'success').observe((Date.now() - cacheStart) / 1000);

    res.json({ message: 'User deleted' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Update user
app.put('/api/users/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { username, email } = req.body;
    
    if (!username && !email) {
      return res.status(400).json({ error: 'Username or email required' });
    }

    const dbStart = Date.now();
    const result = await pool.query(
      'UPDATE users SET username = COALESCE($1, username), email = COALESCE($2, email) WHERE id = $3 RETURNING *',
      [username, email, id]
    );
    databaseQueryDuration.labels('UPDATE', 'users').observe((Date.now() - dbStart) / 1000);

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    // Invalidate caches
    const cacheStart = Date.now();
    await redisClient.del('users:all');
    await redisClient.del(`user:${id}`);
    redisOperationDuration.labels('del', 'success').observe((Date.now() - cacheStart) / 1000);

    res.json({ 
      message: 'User updated', 
      data: result.rows[0] 
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Root endpoint
app.get('/', (req, res) => {
  res.json({ 
    message: 'Hello from CI/CD Pipeline!',
    status: 'success',
    timestamp: new Date().toISOString()
  });
});

// Export for testing
module.exports = { app, pool, redisClient, initializeConnections };

// Start server
if (require.main === module) {
  initializeConnections().then(() => {
    app.listen(port, () => {
      logger.info('App running', { port, url: `http://localhost:${port}` });
    });
  });
}