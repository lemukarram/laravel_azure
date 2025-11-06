FROM php:8.2-fpm-alpine AS base

WORKDIR /var/www/html

# --- Install Base Dependencies ---
# Install MariaDB client developer libraries *before* pdo_mysql
# This is the correct way to provide the SSL libraries for the build
RUN apk add --no-cache mariadb-dev \
    && docker-php-ext-install pdo pdo_mysql \
    && apk del mariadb-dev \
    && docker-php-ext-enable pdo_mysql

# --- Composer Stage ---
# Get composer in its own stage
FROM composer:2.7 AS composer
# No COPY needed here

# --- Development Stage (default) ---
# This is what docker-compose will use
FROM base AS development
ARG TARGETPLATFORM=${BUILDPLATFORM:-linux/amd64}

# Copy composer in
COPY --from=composer /usr/bin/composer /usr/bin/composer

# Set user to www-data for permissions
USER www-data

# --- Production Stage ---
# This is what our CI/CD will build.
# It now includes Nginx AND php-fpm in one image.
FROM base AS prod
ARG TARGETPLATFORM=${BUILDPLATFORM:-linux/amd64}

# --- Install Production Dependencies ---
# Install Nginx and other utilities
# We need ca-certificates for SSL connections (e.g., to Azure MySQL)
RUN apk add --no-cache nginx ca-certificates

# Copy composer in
COPY --from=composer /usr/bin/composer /usr/bin/composer

# Copy application source code
COPY ./src /var/www/html

# Install composer dependencies
RUN composer install --no-dev --no-interaction --no-plugins --no-scripts --prefer-dist

# Optimize Laravel
RUN php artisan config:cache
RUN php artisan route:cache
RUN php artisan view:cache
RUN php artisan event:cache

# Set correct permissions for production
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache

# --- Configure Production Container ---
# Copy in our custom Nginx config for production
COPY nginx.prod.conf /etc/nginx/conf.d/default.conf

# Copy in our startup script
COPY start-prod.sh /usr/local/bin/start-prod.sh
RUN chmod +x /usr/local/bin/start-prod.sh

# Expose port 80 (for Nginx)
EXPOSE 80

# Set the startup command to our custom script
CMD ["/usr/local/bin/start-prod.sh"]