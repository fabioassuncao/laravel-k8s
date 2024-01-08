FROM fabioassuncao/php:8.2-slim

LABEL maintainer="Fábio Assunção fabio@codions.com"


# Configure PHP extensions
RUN docker-php-ext-install -j$(nproc) pcntl

# Copy start script
COPY ./.docker/scripts/start /usr/local/bin/start
RUN chmod +x /usr/local/bin/start

# Copy supervisor config
COPY ./.docker/supervisord/ /etc/supervisor/conf.d

# Copy existing application directory
COPY --chown=www-data:www-data ./ /var/www/html

RUN gosu www-data composer install --no-cache

VOLUME ["/var/www/html/storage"]
