#!/bin/bash

# =============================================================================
# SSL/TLS Setup Script for Let's Encrypt (Certbot)
# =============================================================================
# This script installs Certbot and obtains SSL certificates for Nginx
# 
# Usage: ./setup-ssl.sh <domain> <email> [staging]
#
# Examples:
#   ./setup-ssl.sh example.com admin@example.com
#   ./setup-ssl.sh api.example.com admin@example.com staging
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
DOMAIN="${1:-example.com}"
EMAIL="${2:-admin@example.com}"
STAGING="${3:-false}"
CERT_PATH="/etc/letsencrypt/live/${DOMAIN}"
NGINX_CONF="/etc/nginx/sites-available/default"
WEBROOT="/var/www/html"

# Functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root (use sudo)"
        exit 1
    fi
}

install_certbot() {
    log_info "Installing Certbot..."

    # Update package list
    apt-get update -qq

    # Install Certbot and Nginx plugin
    apt-get install -y -qq certbot python3-certbot-nginx

    log_info "Certbot installed successfully"
}

stop_nginx() {
    log_info "Stopping Nginx..."
    systemctl stop nginx || true
}

start_nginx() {
    log_info "Starting Nginx..."
    systemctl start nginx
}

obtain_certificate() {
    log_info "Obtaining SSL certificate for ${DOMAIN}..."

    if [[ "$STAGING" == "staging" ]]; then
        log_warn "Using Let's Encrypt Staging environment (for testing)"
        STAGING_FLAG="--staging"
    else
        STAGING_FLAG=""
    fi

    # Try standalone mode first (if Nginx not configured)
    certbot certonly \
        --standalone \
        --non-interactive \
        --agree-tos \
        --email "${EMAIL}" \
        ${STAGING_FLAG} \
        -d "${DOMAIN}" \
        -d "www.${DOMAIN}" || {
        
        log_warn "Standalone mode failed, trying webroot mode..."
        
        # Create webroot directory
        mkdir -p "${WEBROOT}"
        
        certbot certonly \
            --webroot \
            --webroot-path "${WEBROOT}" \
            --non-interactive \
            --agree-tos \
            --email "${EMAIL}" \
            ${STAGING_FLAG} \
            -d "${DOMAIN}" \
            -d "www.${DOMAIN}"
    }

    log_info "Certificate obtained successfully"
}

configure_nginx_ssl() {
    log_info "Configuring Nginx with SSL..."

    # Create Nginx configuration
    cat > "${NGINX_CONF}" <<EOF
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name ${DOMAIN} www.${DOMAIN};

    # Let's Encrypt ACME challenge
    location /.well-known/acme-challenge/ {
        root ${WEBROOT};
        allow all;
    }

    location / {
        return 301 https://\$host\$request_uri;
    }
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name ${DOMAIN} www.${DOMAIN};

    # SSL Certificate (managed by Certbot)
    ssl_certificate ${CERT_PATH}/fullchain.pem;
    ssl_certificate_key ${CERT_PATH}/privkey.pem;

    # SSL Settings
    ssl_session_timeout 1d;
    ssl_session_cache shared:SSL:50m;
    ssl_session_tickets off;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;

    ssl_stapling on;
    ssl_stapling_verify on;
    resolver 8.8.8.8 8.8.4.4 valid=300s;
    resolver_timeout 5s;

    # Security Headers
    add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    root ${WEBROOT};
    index index.html index.htm;

    # Proxy to Node.js application
    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }

    # Metrics endpoint
    location /metrics {
        proxy_pass http://127.0.0.1:3000/metrics;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
    }

    # Health check
    location /health {
        proxy_pass http://127.0.0.1:3000/api/health;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
    }
}
EOF

    log_info "Nginx configuration created"
}

test_nginx_config() {
    log_info "Testing Nginx configuration..."
    nginx -t
    log_info "Nginx configuration is valid"
}

enable_nginx() {
    log_info "Enabling and starting Nginx..."
    systemctl enable nginx
    systemctl restart nginx
    log_info "Nginx started successfully"
}

setup_auto_renewal() {
    log_info "Setting up automatic certificate renewal..."

    # Create renewal cron job
    cat > /etc/cron.d/certbot-renew <<EOF
# Let's Encrypt certificate renewal
# Runs twice daily at random minutes
0 0,12 * * * root sleep \$((RANDOM \% 3600)) && certbot renew --quiet --deploy-hook "systemctl reload nginx"
EOF

    chmod 644 /etc/cron.d/certbot-renew

    log_info "Auto-renewal configured"
}

show_certificate_info() {
    log_info "Certificate information:"
    certbot certificates 2>/dev/null || true
}

main() {
    log_info "Starting SSL/TLS setup for ${DOMAIN}..."
    log_info "Email: ${EMAIL}"
    
    check_root
    install_certbot
    stop_nginx
    obtain_certificate
    configure_nginx_ssl
    test_nginx_config
    enable_nginx
    setup_auto_renewal
    show_certificate_info

    log_info "=========================================="
    log_info "SSL/TLS setup completed successfully!"
    log_info "=========================================="
    log_info "Your site is now available at: https://${DOMAIN}"
    log_info "Certificate will auto-renew before expiration"
}

# Run main function
main "$@"