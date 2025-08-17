FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

# 1. Install Apache, PHP5, and php5-mysql
RUN apt-get update && \
    apt-get install -y \
    apache2 \
    php \
    php-mysql \
    wget \
    tar \
    net-tools \
    iputils-ping \
    vim \
    curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*


# 2. Remove default Apache HTML files
RUN rm -rf /var/www/html/*

# 3. Copy and extract application package
COPY devops-demo-1.1.tar.gz /tmp/devops-demo-1.1.tar.gz
RUN tar -xzf /tmp/devops-demo-1.1.tar.gz -C /var/www/html && \
    rm /tmp/devops-demo-1.1.tar.gz

# 4. Set environment variables for MySQL config (customize as needed)
ENV DB_HOST=172.17.0.2 \
    DB_USER=root \
    DB_PASS=root \
    DB_NAME=devopsdb \
    ENV_NAME=Dev

# 5. Replace placeholders in config.ini
RUN sed -i \
    -e "s/DBHOST/${DB_HOST}/g" \
    -e "s/SQLUSER/${DB_USER}/g" \
    -e "s/SQLPASSWORD/${DB_PASS}/g" \
    -e "s/SQLDBNAME/${DB_NAME}/g" \
    -e "s/ENVNAME/${ENV_NAME}/g" \
    /var/www/html/config.ini

# 6. Expose port and start Apache in the foreground
EXPOSE 80
CMD ["apachectl", "-D", "FOREGROUND"]
