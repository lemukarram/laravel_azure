# --- Base Stage ---
# Start from an official PHP 8.2 FPM image (Alpine is lightweight)
FROM php:8.2-fpm-alpine AS base
WORKDIR /var/www/html

# Install system dependencies
RUN apk add --no-cache \
    build-base shadow zip libzip-dev \
    libpng-dev jpeg-dev freetype-dev gd

# Install common Laravel PHP extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg
RUN docker-php-ext-install pdo pdo_mysql zip gd

# --- Composer Stage ---
# Get composer in its own stage
# The 'composer:2.7' image already has the binary at /usr/bin/composer
# We just name this stage 'composer' so other stages can copy from it.
FROM composer:2.7 AS composer
# FIX: Removed the circular 'COPY --from=composer' line that was here.

# --- Development Stage (default) ---
# This is what docker-compose will use
FROM base AS development
# FIX: Added 'ARG' before TARGETPLATFORM
ARG TARGETPLATFORM=${BUILDPLATFORM:-linux/amd64}

# Copy composer in from our 'composer' stage
COPY --from=composer /usr/bin/composer /usr/bin/composer

# Change ownership of the web directory to the web user 'www-data'
RUN chown -R www-data:www-data /var/www/html

# Switch to the 'www-data' user
USER www-data
EXPOSE 9000
CMD ["php-fpm"]

# --- Production Stage ---
# This is what our CI/CD will build
FROM base AS prod
# FIX: Added 'ARG' before TARGETPLATFORM
ARG TARGETPLATFORM=linux/amd64

# Copy composer in from our 'composer' stage
COPY --from=composer /usr/bin/composer /usr/bin/composer

# Copy all of our application code
# The 'src' content will be copied to the root of the workdir
COPY ./src /var/www/html/

# Copy the production .env file that was created by the CI/CD step
COPY ./src/.env /var/www/html/.env

# Install production dependencies (no dev packages)
RUN composer install --no-interaction --no-dev --optimize-autoloader

# Optimize Laravel for production
# This bakes the config and routes into the image for speed
RUN php artisan config:cache && \
    php artisan route:cache && \
    php artisan view:cache

# Set correct permissions for production
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache

USER www-data
EXPOSE 9000
CMD ["php-fpm"]