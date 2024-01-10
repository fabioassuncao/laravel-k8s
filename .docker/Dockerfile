FROM alpine:latest

WORKDIR /var/www/html/

# Essentials
RUN echo "UTC" > /etc/timezone
RUN apk add --no-cache zip unzip curl sqlite bash && \
    sed -i 's/bin\/ash/bin\/bash/g' /etc/passwd

# Installing PHP
RUN apk add --no-cache php83 \
    php83-common \
    php83-pdo \
    php83-opcache \
    php83-zip \
    php83-phar \
    php83-iconv \
    php83-cli \
    php83-curl \
    php83-openssl \
    php83-mbstring \
    php83-tokenizer \
    php83-fileinfo \
    php83-json \
    php83-xml \
    php83-xmlwriter \
    php83-simplexml \
    php83-dom \
    php83-pdo_mysql \
    php83-pdo_sqlite \
    php83-tokenizer \
    php83-pecl-redis \
    php83-intl \
    php83-exif \
    php83-pcntl \
    php83-sockets \
    php83-posix

RUN ln -s /usr/bin/php83 /usr/bin/php

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer

# Download and set up FrankenPHP
ADD https://github.com/dunglas/frankenphp/releases/latest/download/frankenphp-linux-x86_64 /usr/local/bin/frankenphp
RUN chmod +x /usr/local/bin/frankenphp

# Building process
COPY . /var/www/html

RUN composer install --no-dev
RUN chown -R nobody:nobody /var/www/html/storage

COPY ./.docker/entrypoint.sh /usr/local/bin/entrypoint
RUN chmod +x /usr/local/bin/entrypoint

EXPOSE 8000
ENTRYPOINT ["/usr/local/bin/entrypoint"]
