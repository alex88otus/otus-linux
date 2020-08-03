## Урок №32: mysql
### Решение
#### Настройка     
Копирование и изменение конфигов (кроме смены начального пароля), установка, запуск через [Vagrantfile](Vagrantfile).   
Используется:
```bash
mysqld  Ver 8.0.20-11 for Linux on x86_64 (Percona Server (GPL), Release 11, Revision 5b5a5d2)
```
#### Настройка репликации
На мастере (без смены пароля)
```bash
[root@master ~]# mysql
Welcome to the MySQL monitor.  Commands end with ; or \g.
Server version: 8.0.20-11 Percona Server (GPL), Release 11, Revision 5b5a5d2

mysql> SELECT @@server_id;
+-------------+
| @@server_id |
+-------------+
|           1 |
+-------------+
1 row in set (0.00 sec)

mysql>  CREATE DATABASE bet;
Query OK, 1 row affected (0.02 sec)

mysql> \q
Bye
[root@master ~]# mysql -D bet < /vagrant/bet.dmp
[root@master ~]# mysql
mysql> USE bet;
Reading table information for completion of table and column names
You can turn off this feature to get a quicker startup with -A

Database changed
mysql> SHOW TABLES;
+------------------+
| Tables_in_bet    |
+------------------+
| bookmaker        |
| competition      |
| events_on_demand |
| market           |
| odds             |
| outcome          |
| v_same_event     |
+------------------+
7 rows in set (0.00 sec)

mysql> CREATE USER 'repl'@'%' IDENTIFIED BY '!OtusLinux2018';
Query OK, 0 rows affected (0.01 sec)

mysql> SELECT user,host FROM mysql.user where user='repl';
+------+------+
| user | host |
+------+------+
| repl | %    |
+------+------+
1 row in set (0.00 sec)

mysql> GRANT REPLICATION SLAVE ON *.* TO 'repl'@'%';
Query OK, 0 rows affected (0.00 sec)

mysql> \q
Bye
[root@master ~]# mysqldump --all-databases --triggers --routines --events --master-data --ignore-table=bet.events_on_demand --ignore-table=bet.v_same_event > master.sql
[root@master ~]# scp master.sql vagrant@192.168.5.150:/vagrant
vagrant@192.168.5.150's password: 
master.sql                                                  100% 1125KB  37.7MB/s   00:00   
```
На слэйве (без смены пароля)
```bash
[root@slave ~]# mysql
mysql> SELECT @@server_id;
+-------------+
| @@server_id |
+-------------+
|           2 |
+-------------+
1 row in set (0.01 sec)

mysql> SOURCE /vagrant/master.sql

mysql> SHOW DATABASES LIKE 'bet';
+----------------+
| Database (bet) |
+----------------+
| bet            |
+----------------+
1 row in set (0.00 sec)

mysql> USE bet;
Reading table information for completion of table and column names
You can turn off this feature to get a quicker startup with -A

Database changed
mysql>  SHOW TABLES;
+---------------+
| Tables_in_bet |
+---------------+
| bookmaker     |
| competition   |
| market        |
| odds          |
| outcome       |
+---------------+
5 rows in set (0.00 sec)

mysql> CHANGE MASTER TO MASTER_HOST = "192.168.5.100", MASTER_PORT = 3306, MASTER_USER = "repl", MASTER_PASSWORD = "!OtusLinux2018", MASTER_AUTO_POSITION = 1, GET_MASTER_PUBLIC_KEY = 1;
Query OK, 0 rows affected, 2 warnings (0.03 sec)

mysql> START SLAVE;
Query OK, 0 rows affected (0.02 sec)

mysql> SHOW SLAVE STATUS\G
*************************** 1. row ***************************
               Slave_IO_State: Waiting for master to send event
                  Master_Host: 192.168.5.100
                  Master_User: repl
                  Master_Port: 3306
                Connect_Retry: 60
              Master_Log_File: mysql-bin.000002
          Read_Master_Log_Pos: 120506
               Relay_Log_File: slave-relay-bin.000002
                Relay_Log_Pos: 418
        Relay_Master_Log_File: mysql-bin.000002
             Slave_IO_Running: Yes
            Slave_SQL_Running: Yes
              Replicate_Do_DB: 
          Replicate_Ignore_DB: 
           Replicate_Do_Table: 
       Replicate_Ignore_Table: bet.events_on_demand,bet.v_same_event
      Replicate_Wild_Do_Table: 
  Replicate_Wild_Ignore_Table: 
                   Last_Errno: 0
                   Last_Error: 
                 Skip_Counter: 0
          Exec_Master_Log_Pos: 120506
              Relay_Log_Space: 627
              Until_Condition: None
               Until_Log_File: 
                Until_Log_Pos: 0
           Master_SSL_Allowed: No
           Master_SSL_CA_File: 
           Master_SSL_CA_Path: 
              Master_SSL_Cert: 
            Master_SSL_Cipher: 
               Master_SSL_Key: 
        Seconds_Behind_Master: 0
Master_SSL_Verify_Server_Cert: No
                Last_IO_Errno: 0
                Last_IO_Error: 
               Last_SQL_Errno: 0
               Last_SQL_Error: 
  Replicate_Ignore_Server_Ids: 
             Master_Server_Id: 1
                  Master_UUID: b96e573b-d5d0-11ea-b8d9-5254004d77d3
             Master_Info_File: mysql.slave_master_info
                    SQL_Delay: 0
          SQL_Remaining_Delay: NULL
      Slave_SQL_Running_State: Slave has read all relay log; waiting for more updates
           Master_Retry_Count: 86400
                  Master_Bind: 
      Last_IO_Error_Timestamp: 
     Last_SQL_Error_Timestamp: 
               Master_SSL_Crl: 
           Master_SSL_Crlpath: 
           Retrieved_Gtid_Set: 
            Executed_Gtid_Set: 15ed3c14-d5d1-11ea-b8e6-5254004d77d3:1,
b96e573b-d5d0-11ea-b8d9-5254004d77d3:1-39
                Auto_Position: 1
         Replicate_Rewrite_DB: 
                 Channel_Name: 
           Master_TLS_Version: 
       Master_public_key_path: 
        Get_master_public_key: 1
            Network_Namespace: 
1 row in set (0.01 sec)
```
#### Проверка
На мастере
```bash
mysql>  USE bet;
Reading table information for completion of table and column names
You can turn off this feature to get a quicker startup with -A

Database changed
mysql>  INSERT INTO bookmaker (id,bookmaker_name) VALUES(1,'1xbet');
Query OK, 1 row affected (0.00 sec)

mysql>  INSERT INTO bookmaker (id,bookmaker_name) VALUES(777,'azino777');
Query OK, 1 row affected (0.00 sec)
```
На слэйве
```bash
mysql> SELECT * FROM bookmaker;
+-----+----------------+
| id  | bookmaker_name |
+-----+----------------+
|   1 | 1xbet          |
| 777 | azino777       |
|   4 | betway         |
|   5 | bwin           |
|   6 | ladbrokes      |
|   3 | unibet         |
+-----+----------------+
6 rows in set (0.00 sec)

mysql> \q
Bye
[root@slave mysql]# mysqlbinlog mysql-bin.000002
/*!50530 SET @@SESSION.PSEUDO_SLAVE_MODE=1*/;
/*!50003 SET @OLD_COMPLETION_TYPE=@@COMPLETION_TYPE,COMPLETION_TYPE=0*/;
DELIMITER /*!*/;
# at 4
#200803 21:34:24 server id 2  end_log_pos 125 CRC32 0x4cf19561 	Start: binlog v 4, server v 8.0.20-11 created 200803 21:34:24 at startup
# Warning: this binlog is either in use or was not closed properly.
ROLLBACK/*!*/;
BINLOG '
4IIoXw8CAAAAeQAAAH0AAAABAAQAOC4wLjIwLTExAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAADggihfEwANAAgAAAAABAAEAAAAYQAEGggAAAAICAgCAAAACgoKKioAEjQA
CigBYZXxTA==
'/*!*/;
# at 125
#200803 21:34:24 server id 2  end_log_pos 156 CRC32 0x50b360d2 	Previous-GTIDs
# [empty]
# at 156
#200803 22:07:15 server id 2  end_log_pos 235 CRC32 0x3aada516 	GTID	last_committed=0	sequence_number=1	rbr_only=no	original_committed_timestamp=1596492435595626	immediate_commit_timestamp=1596492435595626	transaction_length=336
# original_commit_timestamp=1596492435595626 (2020-08-03 22:07:15.595626 UTC)
# immediate_commit_timestamp=1596492435595626 (2020-08-03 22:07:15.595626 UTC)
/*!80001 SET @@session.original_commit_timestamp=1596492435595626*//*!*/;
/*!80014 SET @@session.original_server_version=80020*//*!*/;
/*!80014 SET @@session.immediate_server_version=80020*//*!*/;
SET @@SESSION.GTID_NEXT= '15ed3c14-d5d1-11ea-b8e6-5254004d77d3:1'/*!*/;
# at 235
#200803 22:07:15 server id 2  end_log_pos 492 CRC32 0x92366d75 	Query	thread_id=9	exec_time=0	error_code=0	Xid = 5
SET TIMESTAMP=1596492435.579385/*!*/;
SET @@session.pseudo_thread_id=9/*!*/;
SET @@session.foreign_key_checks=1, @@session.sql_auto_is_null=0, @@session.unique_checks=1, @@session.autocommit=1/*!*/;
SET @@session.sql_mode=1168113696/*!*/;
SET @@session.auto_increment_increment=1, @@session.auto_increment_offset=1/*!*/;
/*!\C utf8mb4 *//*!*/;
SET @@session.character_set_client=255,@@session.collation_connection=255,@@session.collation_server=255/*!*/;
SET @@session.time_zone='SYSTEM'/*!*/;
SET @@session.lc_time_names=0/*!*/;
SET @@session.collation_database=DEFAULT/*!*/;
/*!80011 SET @@session.default_collation_for_utf8mb4=255*//*!*/;
ALTER USER 'root'@'localhost' IDENTIFIED WITH 'caching_sha2_password' AS '$A$005${!~	9ut\'U5O:%^/CRm{1CL1RlPd7CfNZuGZfWiiWecznGosSIHF1rTN6h4Jl96'
/*!*/;
# at 492
#200803 22:13:50 server id 1  end_log_pos 578 CRC32 0x13e5b50a 	GTID	last_committed=1	sequence_number=2	rbr_only=no	original_committed_timestamp=1596492830846091	immediate_commit_timestamp=1596492830848419	transaction_length=323
# original_commit_timestamp=1596492830846091 (2020-08-03 22:13:50.846091 UTC)
# immediate_commit_timestamp=1596492830848419 (2020-08-03 22:13:50.848419 UTC)
/*!80001 SET @@session.original_commit_timestamp=1596492830846091*//*!*/;
/*!80014 SET @@session.original_server_version=80020*//*!*/;
/*!80014 SET @@session.immediate_server_version=80020*//*!*/;
SET @@SESSION.GTID_NEXT= 'b96e573b-d5d0-11ea-b8d9-5254004d77d3:40'/*!*/;
# at 578
#200803 22:13:50 server id 1  end_log_pos 654 CRC32 0xfe9b6b5d 	Query	thread_id=17	exec_time=0	error_code=0
SET TIMESTAMP=1596492830/*!*/;
BEGIN
/*!*/;
# at 654
#200803 22:13:50 server id 1  end_log_pos 784 CRC32 0x17581928 	Query	thread_id=17	exec_time=0	error_code=0
use `bet`/*!*/;
SET TIMESTAMP=1596492830/*!*/;
INSERT INTO bookmaker (id,bookmaker_name) VALUES(1,'1xbet')
/*!*/;
# at 784
#200803 22:13:50 server id 1  end_log_pos 815 CRC32 0xc02616f2 	Xid = 430
COMMIT/*!*/;
# at 815
#200803 22:14:00 server id 1  end_log_pos 901 CRC32 0x017a543c 	GTID	last_committed=2	sequence_number=3	rbr_only=no	original_committed_timestamp=1596492840654642	immediate_commit_timestamp=1596492840655060	transaction_length=328
# original_commit_timestamp=1596492840654642 (2020-08-03 22:14:00.654642 UTC)
# immediate_commit_timestamp=1596492840655060 (2020-08-03 22:14:00.655060 UTC)
/*!80001 SET @@session.original_commit_timestamp=1596492840654642*//*!*/;
/*!80014 SET @@session.original_server_version=80020*//*!*/;
/*!80014 SET @@session.immediate_server_version=80020*//*!*/;
SET @@SESSION.GTID_NEXT= 'b96e573b-d5d0-11ea-b8d9-5254004d77d3:41'/*!*/;
# at 901
#200803 22:14:00 server id 1  end_log_pos 977 CRC32 0x8f6ed9ba 	Query	thread_id=17	exec_time=0	error_code=0
SET TIMESTAMP=1596492840/*!*/;
BEGIN
/*!*/;
# at 977
#200803 22:14:00 server id 1  end_log_pos 1112 CRC32 0xdc90e0a6 	Query	thread_id=17	exec_time=0	error_code=0
SET TIMESTAMP=1596492840/*!*/;
INSERT INTO bookmaker (id,bookmaker_name) VALUES(777,'azino777')
/*!*/;
# at 1112
#200803 22:14:00 server id 1  end_log_pos 1143 CRC32 0x9ef24620 	Xid = 432
COMMIT/*!*/;
SET @@SESSION.GTID_NEXT= 'AUTOMATIC' /* added by mysqlbinlog */ /*!*/;
DELIMITER ;
# End of log file
/*!50003 SET COMPLETION_TYPE=@OLD_COMPLETION_TYPE*/;
/*!50530 SET @@SESSION.PSEUDO_SLAVE_MODE=0*/;
```
### Конец решения
### Выполненo
