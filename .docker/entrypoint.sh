#!/bin/bash

set -e

# Run our defined exec if args empty
if [ -z "$1" ]; then

    : ${CONTAINER_MODE:='manual'}
    : ${CONTAINER_ROLE:='app'}
    : ${APP_ENV:='production'}
    artisan="php -d variables_order=EGPCS /var/www/html/artisan"

        if [ "$CONTAINER_MODE" = "automatic" ]; then
            echo "Preparing application..."
            chown -R nobody:nobody /var/www/html/storage
            php artisan storage:link || true
            php artisan config:cache || true
            php artisan migrate --force || true
        fi

    if [ "$CONTAINER_ROLE" = "app" ]; then

        echo "INFO: Running octane..."
        exec $artisan octane:start --server=frankenphp --host=0.0.0.0 --port=8000

    elif [ "$CONTAINER_ROLE" = "worker" ]; then

        echo "INFO: Running the queue..."
        exec $artisan queue:work -vv --no-interaction --tries=3 --sleep=5 --timeout=300 --delay=10

    elif [ "$CONTAINER_ROLE" = "horizon" ]; then

        echo "INFO: Running the horizon..."
        exec $artisan horizon

    elif [ "$CONTAINER_ROLE" = "scheduler" ]; then

        while true; do
            if [ -d "/var/www/html/vendor" ] ; then
                echo "INFO: Running scheduled tasks."
                exec $artisan schedule:run --verbose --no-interaction &
            else
                echo "WARNING: Directory /var/www/html/vendor does not yet exist."
            fi
            sleep 60s
        done

    else
        echo "Could not match the container role \"$CONTAINER_ROLE\""
        exit 1
    fi

else
    exec "$@"
fi
