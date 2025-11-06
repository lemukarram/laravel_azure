#!/bin/sh

# Start the PHP-FPM processor
php-fpm &

# Start the Nginx web server
# 'daemon off;' is crucial for running Nginx in the foreground
nginx -g 'daemon off;'