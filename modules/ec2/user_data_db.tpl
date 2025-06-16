#!/bin/bash

# Install MariaDB client
sudo apt-get update -y
sudo apt-get install -y mariadb-client mariadb-server

echo "Waiting for DB endpoint to be ready..."
until mysql -h ${db_endpoint} -u ${db_user} -p${db_pass} -e "SELECT 1" &>/dev/null; do
  echo "Waiting for RDS to accept connections..."
  sleep 10
done
echo "Writing SQL file to /tmp..."
echo "${student_sql}" | base64 -d > /tmp/studentapp.sql

sudo systemctl start mariadb
# Test connection and create database
echo "Creating database on RDS..."
# clean_endpoint=$(echo "${db_endpoint}" | sed 's/:3306//')
mysql -h ${db_endpoint} -u ${db_user} -p${db_pass} -e "CREATE DATABASE IF NOT EXISTS studentapp;"


# Import the SQL schema into the studentapp database
echo "Importing schema..."
mysql -h ${db_endpoint} -u ${db_user} -p${db_pass} studentapp < /tmp/studentapp.sql

echo "Done with database setup."


