#!/bin/bash

set -e

# Set default values if not provided
: ${CONTAINER_MODE:='manual'}
: ${CONTAINER_ROLE:='app'}
: ${APP_ENV:='production'}
ARTISAN="php -d variables_order=EGPCS /var/www/html/artisan"

# Run setup tasks if in automatic mode
if [ "$CONTAINER_MODE" = "automatic" ]; then
    echo "Preparing application..."
    chown -R nobody:nobody /var/www/html/storage
    php artisan storage:link || true
    php artisan config:cache || true
    php artisan migrate --force || true
fi

# Check if vendor directory exists
check_vendor_directory() {
    if [ -d "/var/www/html/vendor" ]; then
        return 0
    else
        if [ "$APP_ENV" = "local" ]; then
            echo "WARNING: Directory /var/www/html/vendor does not yet exist."
        else
            echo "ERROR: Directory /var/www/html/vendor does not exist. Exiting..."
            exit 1
        fi
    fi
}

# Execute role-specific commands
case "$CONTAINER_ROLE" in
    app)
        echo "INFO: Running octane..."
        check_vendor_directory && exec $ARTISAN octane:start --server=frankenphp --host=0.0.0.0 --port=8000
        ;;
    worker)
        echo "INFO: Running the queue..."
        check_vendor_directory && exec $ARTISAN queue:work -vv --no-interaction --tries=3 --sleep=5 --timeout=300 --delay=10
        ;;
    horizon)
        echo "INFO: Running the horizon..."
        check_vendor_directory && exec $ARTISAN horizon
        ;;
    scheduler)
        while true; do
            check_vendor_directory && echo "INFO: Running scheduled tasks." && exec $ARTISAN schedule:run --verbose --no-interaction &
            sleep 60s
        done
        ;;
    *)
        echo "Could not match the container role \"$CONTAINER_ROLE\""
        exit 1
        ;;
esac
