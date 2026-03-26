# Nginx Dockerfile with SSL/TLS support
# This Dockerfile builds an Nginx image with SSL certificates

FROM nginx:alpine

# Install certbot for SSL certificate management
RUN apk add --no-cache certbot bash

# Copy custom Nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf
COPY ssl.conf /etc/nginx/ssl.conf
COPY conf.d /etc/nginx/conf.d

# Create directories for SSL certificates and ACME challenge
RUN mkdir -p /etc/letsencrypt/live /var/www/html/.well-known/acme-challenge

# Expose HTTP and HTTPS ports
EXPOSE 80 443

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD wget -q --spider http://localhost/health || exit 1

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]