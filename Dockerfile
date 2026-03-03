FROM php:8.2-apache

# Install dependencies for MediaWiki + PostgreSQL + Redis
RUN apt-get update && apt-get install -y \
    libpq-dev \
    libicu-dev \
    libxml2-dev \
    libonig-dev \
    liblua5.1-0-dev \
    lua5.1 \
    imagemagick \
    git \
    && docker-php-ext-install \
        pgsql \
        pdo_pgsql \
        intl \
        mbstring \
        xml \
        calendar \
    && pecl install redis \
    && docker-php-ext-enable redis \
    && a2enmod rewrite \
    && rm -rf /var/lib/apt/lists/* \
    && sed -i '/<Directory \/var\/www\/>/,/<\/Directory>/ s/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf

# Copy MediaWiki source
COPY mediawiki/ /var/www/html/

# Copy entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Short URL rewrite rules
RUN echo 'RewriteEngine On\n\
RewriteRule ^/?wiki(/.*)?$ %{DOCUMENT_ROOT}/index.php [L]\n\
RewriteRule ^/?$ %{DOCUMENT_ROOT}/index.php [L]' > /var/www/html/.htaccess

# Set proper permissions
RUN mkdir -p /var/www/html/images /var/www/html/cache \
    && chown -R www-data:www-data /var/www/html/images \
    && chown -R www-data:www-data /var/www/html/cache

ENTRYPOINT ["/entrypoint.sh"]
