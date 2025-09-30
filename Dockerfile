# Eckmar v2.0.1 - PHP 7.4 + Apache
FROM php:7.4-apache

# System deps + PHP build deps
RUN apt-get update && apt-get install -y \
    $PHPIZE_DEPS \
    git unzip libzip-dev libxml2-dev libgmp-dev libonig-dev \
    libpng-dev libjpeg62-turbo-dev libfreetype6-dev \
 && rm -rf /var/lib/apt/lists/*

# PHP extensions required by the app
RUN docker-php-ext-configure zip \
 && docker-php-ext-install -j$(nproc) pdo_mysql zip bcmath gmp mbstring

# GD (needed by gregwar/captcha)
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
 && docker-php-ext-install -j$(nproc) gd

# Pretty URLs for Laravel
RUN a2enmod rewrite

# Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Use Laravel's public/ as the web root
ENV APACHE_DOCUMENT_ROOT=/var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf

# Allow .htaccess (needed for pretty URLs) + grant access
RUN printf '<Directory ${APACHE_DOCUMENT_ROOT}>\n\tAllowOverride All\n\tRequire all granted\n</Directory>\n' > /etc/apache2/conf-available/laravel.conf \
 && a2enconf laravel


WORKDIR /var/www/html
