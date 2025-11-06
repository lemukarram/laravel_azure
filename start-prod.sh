#!/bin/sh

# Set the script to exit immediately if any command fails
set -e

# 1. Run database migrations
#    We run this first. If it fails, the script will exit,
#    the container will crash, and Azure will report an error.
#    This is GOOD, as we don't want to start an app
#    that can't talk to its database.
echo "Running database migrations..."
php artisan migrate --force

# 2. Start the PHP-FPM processor
#    Run it in the background (&)
echo "Starting PHP-FPM..."
php-fpm &

# 3. Start the Nginx web server
#    Run it in the foreground (daemon off;)
#    This is the main process that keeps the container alive.
echo "Starting Nginx..."
nginx -g 'daemon off;'