FROM php:8.3-alpine

LABEL maintainer="Fábio Assunção <fabio23gt@gmail.com>"

# Install necessary tools
RUN apk --no-cache add \
    bash \
    curl \
    libzip-dev \
    unzip

# Install php-extension-installer
COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer

# Install required PHP extensions
RUN install-php-extensions pcntl sockets

# Set the working directory
WORKDIR /var/www

# Copy application files
COPY . /var/www

# Download and set up FrankenPHP
ADD https://github.com/dunglas/frankenphp/releases/latest/download/frankenphp-linux-x86_64 /usr/local/bin/frankenphp
RUN chmod +x /usr/local/bin/frankenphp

# Install Composer dependencies
RUN composer install --no-dev

# Entrypoint command
ENTRYPOINT ["php", "artisan", "octane:start", "--server=frankenphp", "--port=8000", "--workers=16", "--host=0.0.0.0"]
