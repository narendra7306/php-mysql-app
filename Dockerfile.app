FROM php:8.2-apache

# Install PHP MySQL extension
RUN docker-php-ext-install mysqli pdo pdo_mysql

# Enable Apache rewrite (commonly needed)
RUN a2enmod rewrite

# Remove default html
RUN rm -rf /var/www/html/*

# Copy app
COPY devops-demo-1.1.tar.gz /tmp/
RUN tar -xzf /tmp/devops-demo-1.1.tar.gz -C /var/www/html \
    && rm /tmp/devops-demo-1.1.tar.gz

EXPOSE 80
