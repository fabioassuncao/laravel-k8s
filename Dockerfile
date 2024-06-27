FROM ghcr.io/fabioassuncao/php:8.3

# Download and set up FrankenPHP
ADD https://github.com/dunglas/frankenphp/releases/latest/download/frankenphp-linux-x86_64 /usr/local/bin/frankenphp
RUN chmod +x /usr/local/bin/frankenphp

# Building process
COPY . /var/www/html
RUN composer install && \
    chown -R nobody:nobody /var/www/html/storage
