## Урок №29: **postgresql**
### Решение
#### Репликация и бэкапирование
Стенд описан в [Vagrantfile](Vagrantfile) - 3 хоста: base, replica, backup.   
Провижининг ансиблом.   
В комплекте:   
[playbook.yml](provisioning/playbook.yml)   
[.pgpass](provisioning/.pgpass) с параметрами подключения к "мастеру" base для replica и backup   
[postgresql.conf.base](provisioning/postgresql.conf.base), [pg_hba.conf.base](provisioning/pg_hba.conf.base) - конфиги для "мастера"   
[postgresql.conf.replica](provisioning/postgresql.conf.replica) - конфиг для слэйва   
[borg_backup.sh](provisioning/borg_backup.sh), [root](provisioning/root) - бэкап-скрипт для backup   
#### Проверка репликации
В созданную заранее тестовую таблицу *guestbook* заинсертим некоторое количество раз некоторые значения на мастер-сервере и проверим.
```bash
vagrant ssh base
Last login: Wed Jul  1 18:03:06 2020 from 10.0.2.2
[vagrant@base ~]$ sudo -s
[root@base vagrant]# sudo -u postgres psql
could not change directory to "/home/vagrant": Permission denied
psql (12.3)
Type "help" for help.

postgres=# INSERT INTO guestbook (visitor_email, date, message) VALUES ('jim@gmail.com', current_date, 'Now we are replicating.');
INSERT 0 1
******
postgres=# select * from guestbook;
 visitor_email | vistor_id |        date         |         message         
---------------+-----------+---------------------+-------------------------
 jim@gmail.com |         1 | 2020-07-01 00:00:00 | This is a test
 jim@gmail.com |         2 | 2020-07-01 00:00:00 | Now we are replicating.
******
jim@gmail.com |       126 | 2020-07-01 00:00:00 | Now we are replicating.
(126 rows)

postgres=# \q
[root@base vagrant]# 
```
Сразу же проверим репликацию на сервере-реплике
```bash
vagrant ssh replica
Last login: Wed Jul  1 18:15:27 2020 from 10.0.2.2
[vagrant@replica ~]$ sudo -s
[root@replica vagrant]# sudo -u postgres psql
could not change directory to "/home/vagrant": Permission denied
psql (12.3)
Type "help" for help.

postgres=# select * from guestbook;
 visitor_email | vistor_id |        date         |         message         
---------------+-----------+---------------------+-------------------------
 jim@gmail.com |         1 | 2020-07-01 00:00:00 | This is a test
 jim@gmail.com |         2 | 2020-07-01 00:00:00 | Now we are replicating.
******
 jim@gmail.com |       126 | 2020-07-01 00:00:00 | Now we are replicating.
(126 rows)

postgres=# \q
[root@replica vagrant]# 
```
#### Проверка бэкапирвания
Архивация каждые 5 минут
```bash
[root@backup ~]# cat /var/log/borg.log
******
------------------------------------------------------------------------------
2020-07-01T21:00:02+0000 BORGBACKUP CREATE
------------------------------------------------------------------------------
Archive name: postgres_2020-07-01T21:00:02
Archive fingerprint: 9e1659ddcebe16260ce004d56cd090a873482b7c64fc2e9104a92f18a9685cb0
Time (start): Wed, 2020-07-01 21:00:02
Time (end):   Wed, 2020-07-01 21:00:03
Duration: 0.61 seconds
Number of files: 988
Utilization of max. archive size: 0%
------------------------------------------------------------------------------
                       Original size      Compressed size    Deduplicated size
This archive:               41.68 MB              1.94 MB             32.28 kB
All archives:              750.15 MB             34.98 MB              1.38 MB

                       Unique chunks         Total chunks
Chunk index:                     459                14712
------------------------------------------------------------------------------
DONE
------------------------------------------------------------------------------
------------------------------------------------------------------------------
2020-07-01T21:00:02+0000 BORGBACKUP PRUNE
------------------------------------------------------------------------------
Keeping archive: postgres_2020-07-01T21:00:02         Wed, 2020-07-01 21:00:02 [9e1659ddcebe16260ce004d56cd090a873482b7c64fc2e9104a92f18a9685cb0]
******
Keeping archive: postgres_2020-07-01T19:28:14         Wed, 2020-07-01 19:28:14 [4b799be50b9a08f0235015a5baaa688ac8f50150d96db7f12e0dd7463c170231]
------------------------------------------------------------------------------
DONE
[root@backup ~]# borg mount /home/vagrant/pg_borg_backups/ /mnt
Enter passphrase for key /home/vagrant/pg_borg_backups: 
[root@backup ~]# ll /mnt
total 0
drwxr-xr-x. 1 root root 0 Jul  1 19:28 postgres_2020-07-01T19:28:14
******
drwxr-xr-x. 1 root root 0 Jul  1 21:05 postgres_2020-07-01T21:05:01
[root@backup ~]# ll /mnt/postgres_2020-07-01T21\:05\:01/var/lib/pgsql/12/data/
total 18
-rw-------. 1 postgres postgres     3 Jul  1 21:05 PG_VERSION
-rw-------. 1 postgres postgres   226 Jul  1 21:05 backup_label
drwx------. 1 postgres postgres     0 Jul  1 21:05 base
-rw-------. 1 postgres postgres    30 Jul  1 21:05 current_logfiles
drwx------. 1 postgres postgres     0 Jul  1 21:05 global
drwx------. 1 postgres postgres     0 Jul  1 21:05 log
drwx------. 1 postgres postgres     0 Jul  1 21:05 pg_commit_ts
drwx------. 1 postgres postgres     0 Jul  1 21:05 pg_dynshmem
-rw-------. 1 postgres postgres   786 Jul  1 21:05 pg_hba.conf
-rw-------. 1 postgres postgres  1636 Jul  1 21:05 pg_ident.conf
drwx------. 1 postgres postgres     0 Jul  1 21:05 pg_logical
drwx------. 1 postgres postgres     0 Jul  1 21:05 pg_multixact
drwx------. 1 postgres postgres     0 Jul  1 21:05 pg_notify
drwx------. 1 postgres postgres     0 Jul  1 21:05 pg_replslot
drwx------. 1 postgres postgres     0 Jul  1 21:05 pg_serial
drwx------. 1 postgres postgres     0 Jul  1 21:05 pg_snapshots
drwx------. 1 postgres postgres     0 Jul  1 21:05 pg_stat
drwx------. 1 postgres postgres     0 Jul  1 21:05 pg_stat_tmp
drwx------. 1 postgres postgres     0 Jul  1 21:05 pg_subtrans
drwx------. 1 postgres postgres     0 Jul  1 21:05 pg_tblspc
drwx------. 1 postgres postgres     0 Jul  1 21:05 pg_twophase
drwx------. 1 postgres postgres     0 Jul  1 21:05 pg_wal
drwx------. 1 postgres postgres     0 Jul  1 21:05 pg_xact
-rw-------. 1 postgres postgres   283 Jul  1 21:05 postgresql.auto.conf
-rw-------. 1 postgres postgres 12296 Jul  1 21:05 postgresql.conf
-rw-------. 1 postgres postgres     0 Jul  1 21:05 standby.signal
```
Всё на месте
### Конец решения
### Выполненo