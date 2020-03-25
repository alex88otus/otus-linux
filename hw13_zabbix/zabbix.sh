yum install -y epel-release wget nano 
yum install -y zabbix40-server-mysql.x86_64 zabbix40-dbfiles-mysql.noarch
yum install -y https://dev.mysql.com/get/mysql80-community-release-el7-3.noarch.rpm
yum install -y mysql-community-server.x86_64
systemctl start mysqld
# Shows temp mysql password for user root 
sed -r 's/temporary password.+:{1} (.+)$/\1/g' /var/log/mysqld.log
mysql -u root -p
ALTER USER 'root'@'localhost' identified by 'QwErTy1@3$';
ALTER USER 'root'@'localhost' PASSWORD EXPIRE NEVER;
create database zabbix character set utf8 collate utf8_bin;
create user 'zabbix'@'localhost' IDENTIFIED WITH mysql_native_password by 'QwErTy1@3$';
grant all privileges on zabbix.* to 'zabbix'@'localhost';
quit;

cd /usr/share/zabbix-mysql/
mysql -uzabbix -pQwErTy1@3$ zabbix < schema.sql
mysql -uzabbix -pQwErTy1@3$ zabbix < images.sql
mysql -uzabbix -pQwErTy1@3$ zabbix < data.sql

yum install -y zabbix40-web-mysql zabbix40-agent
