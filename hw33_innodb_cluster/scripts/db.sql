CREATE DATABASE wpdb;
CREATE USER 'wpdbuser'@'%' IDENTIFIED BY 'wpdbuser';
GRANT ALL PRIVILEGES ON wpdb.* TO 'wpdbuser'@'%';
