## Урок №33: InnoDB Cluster в Docker
### Решение
#### Запуск
Запускается `docker-compose up`.   
Имеет в себе 3 интанса MySQL + MySQL Shell для настройки + MySQL Router для внешних подключений + Wordpress для проверки.   
Через 5 мин для проверки `localhost:8080`
#### Проверка через MySQL Shell
Запустим MySQL Shell в той же сети, что создалась при старте и подключимся к MySQL Router
```bash
docker run -it --net=hw33_innodb_cluster_default --entrypoint /bin/bash bkandasa/mysql-shell-batch
bash-4.2# mysqlsh
MySQL Shell 8.0.13

Copyright (c) 2016, 2018, Oracle and/or its affiliates. All rights reserved.

Oracle is a registered trademark of Oracle Corporation and/or its
affiliates. Other names may be trademarks of their respective
owners.

Type '\help' or '\?' for help; '\quit' to exit.


 MySQL  JS > \c root@mysql-router:6446
Creating a session to 'root@mysql-router:6446'
Please provide the password for 'root@mysql-router:6446': *****
Fetching schema names for autocompletion... Press ^C to stop.
Your MySQL connection id is 6872
Server version: 8.0.13 MySQL Community Server - GPL
No default schema selected; type \use <schema> to set one.

 MySQL  mysql-router:6446 ssl  JS > var cluster = dba.getCluster()
 MySQL  mysql-router:6446 ssl  JS > cluster.status()
{
    "clusterName": "devCluster", 
    "defaultReplicaSet": {
        "name": "default", 
        "primary": "mysql-server-1:3306", 
        "ssl": "REQUIRED", 
        "status": "OK", 
        "statusText": "Cluster is ONLINE and can tolerate up to ONE failure.", 
        "topology": {
            "mysql-server-1:3306": {
                "address": "mysql-server-1:3306", 
                "mode": "R/W", 
                "readReplicas": {}, 
                "role": "HA", 
                "status": "ONLINE"
            }, 
            "mysql-server-2:3306": {
                "address": "mysql-server-2:3306", 
                "mode": "R/O", 
                "readReplicas": {}, 
                "role": "HA", 
                "status": "ONLINE"
            }, 
            "mysql-server-3:3306": {
                "address": "mysql-server-3:3306", 
                "mode": "R/O", 
                "readReplicas": {}, 
                "role": "HA", 
                "status": "ONLINE"
            }
        }
    }, 
    "groupInformationSourceMember": "mysql://root@mysql-router:6446"
}
```
Работает.
### Конец решения
### Выполненo