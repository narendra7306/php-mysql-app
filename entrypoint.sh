#!/bin/bash

# Replace placeholders in config.ini
sed -i \
    -e "s/DBHOST/${DBHOST}/g" \
    -e "s/SQLUSER/${DBUSER}/g" \
    -e "s/SQLPASSWORD/${DBPASS}/g" \
    -e "s/SQLDBNAME/${DBNAME}/g" \
    -e "s/ENVNAME/${ENVNAME}/g" \
    /var/www/html/config.ini

# Start Apache in the foreground
exec "$@"

