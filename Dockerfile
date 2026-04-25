FROM php:8.3-fpm-bookworm

ENV DEBIAN_FRONTEND=noninteractive

# System deps
RUN apt-get update && apt-get install -y \
    nginx \
    supervisor \
    git \
    unzip \
    curl \
    libzip-dev \
    libxml2-dev \
    libicu-dev \
    libpng-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    libonig-dev \
    libcurl4-openssl-dev \
    libssl-dev \
    libxslt1-dev \
    libexif-dev \
    libzip4 \
    && rm -rf /var/lib/apt/lists/*

# PHP extensions (TastyIgniter requirement-complete)
RUN docker-php-ext-configure gd --with-freetype --with-jpeg && \
    docker-php-ext-install \
        bcmath \
        gd \
        mbstring \
        pdo_mysql \
        zip \
        xml \
        intl \
        curl \
        exif \
        dom \
        ctype \
        opcache

# Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /app

# Copy project first (better layer caching)
COPY . /app

# Install dependencies
RUN composer install \
    --no-dev \
    --no-interaction \
    --prefer-dist \
    --optimize-autoloader

# Writable dirs (Laravel/TI requirement)
RUN mkdir -p storage bootstrap/cache && \
    chown -R www-data:www-data /app && \
    chmod -R 775 storage bootstrap/cache

# Nginx + supervisor config
COPY docker/nginx.conf /etc/nginx/sites-available/default
COPY docker/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

EXPOSE 8080

CMD ["/usr/bin/supervisord", "-n"]
