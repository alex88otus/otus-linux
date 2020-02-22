## Урок №5: **sistemd**
### Решение
#### 0. Создаем VM
```bash
vagrant init centos/7
```
#### 1. Написать сервис **watchlog**, запускаемый по расписанию

Необходимые файлы расположем в подкаталоге рабочего каталога [watchlog](watchlog), посмотрим что внутри

`cat etc/sysconfig/watchlog`
```bash
# Configuration file for my watchdog service
# Place it to /etc/sysconfig
# File and word in that file that we will be monit
WORD="ALERT"
LOG=/var/log/watchlog.log
```
`cat etc/systemd/system/watchlog.service`
```bash
[Unit]
Description=My watchlog service
[Service]
Type=oneshot
EnvironmentFile=/etc/sysconfig/watchlog
ExecStart=/opt/watchlog.sh $WORD $LOG
```
`cat etc/systemd/system/watchlog.timer`
```bash
[Unit]
Description=Run watchlog script every 5 second
Requires=watchlog.service
[Timer]
# Run every 5 second
OnUnitActiveSec=5
AccuracySec=1us
Unit=watchlog.service
[Install]
WantedBy=multi-user.target
```
`cat opt/watchlog.sh`
```bash
#!/bin/bash
WORD=$1
LOG=$2
DATE=`date`
if grep $WORD $LOG &> /dev/null
then
logger "$DATE: I found word, Master!"
else
exit 0
fi
```
`cat var/log/watchlog.log`
```bash
ALERT
```
При запуске VM этот каталог скопируется внутрь гостевой системы в каталог `/vagrant`.  Скопируем файлы сервиса в необходимые каталоги, сделаем файл скрипта исполняемым
```bash
sudo -s
cp -r /vagrant/watchlog/* /
chmod +x /opt/watchlog.sh
```
Запустим *timer* командой `systemctl start watchlog.timer`, проверим работу
```bash
[root@localhost vagrant]# tail -f /var/log/messages
Feb 22 12:51:53 localhost systemd: Starting My watchlog service...
Feb 22 12:51:53 localhost root: Sat Feb 22 12:51:53 UTC 2020: I found word, Master!
Feb 22 12:51:53 localhost systemd: Started My watchlog service.
Feb 22 12:51:58 localhost systemd: Starting My watchlog service...
Feb 22 12:51:58 localhost root: Sat Feb 22 12:51:58 UTC 2020: I found word, Master!
Feb 22 12:51:58 localhost systemd: Started My watchlog service.
Feb 22 12:52:03 localhost systemd: Starting My watchlog service...
Feb 22 12:52:03 localhost root: Sat Feb 22 12:52:03 UTC 2020: I found word, Master!
Feb 22 12:52:03 localhost systemd: Started My watchlog service.
Feb 22 12:52:08 localhost systemd: Starting My watchlog service...
Feb 22 12:52:08 localhost root: Sat Feb 22 12:52:08 UTC 2020: I found word, Master!
Feb 22 12:52:08 localhost systemd: Started My watchlog service.
```
Работает корректно
#### 2. Из репозитория epel установить spawn-fcgi и переписать init-скрипт на unit-файл (имя service должно называться так же: spawn-fcgi)

Устанавливаем необходимые пакеты
```bash
yum install epel-release -y && yum install spawn-fcgi php php-cli mod_fcgid httpd -y
```
```bash
# You must set some working options before the "spawn-fcgi" service will work.
# If SOCKET points to a file, then this file is cleaned up by the init script.
#
# See spawn-fcgi(1) for all possible options.
#
# Example :
SOCKET=/var/run/php-fcgi.sock
OPTIONS="-u apache -g apache -s $SOCKET -S -M 0600 -C 32 -F 1 -P /var/run/spawn-fcgi.pid -- /usr/bin/php-cgi"
```
```
```bash
[Unit]
Description=Spawn-fcgi startup service by Otus
After=network.target
[Service]
Type=simple
PIDFile=/var/run/spawn-fcgi.pid
EnvironmentFile=/etc/sysconfig/spawn-fcgi
ExecStart=/usr/bin/spawn-fcgi -n $OPTIONS
KillMode=process
[Install]
WantedBy=multi-user.target
```
yes | cp -fr /vagrant/spawn-fcgi/* /

```bash
[root@localhost vagrant]# systemctl start spawn-fcgi
[root@localhost vagrant]# systemctl status spawn-fcgi
● spawn-fcgi.service - Spawn-fcgi startup service by Otus
   Loaded: loaded (/etc/systemd/system/spawn-fcgi.service; disabled; vendor preset: disabled)
   Active: active (running) since Sat 2020-02-22 13:39:21 UTC; 5s ago
 Main PID: 5097 (php-cgi)
   CGroup: /system.slice/spawn-fcgi.service
           ├─5097 /usr/bin/php-cgi
           ├─5098 /usr/bin/php-cgi
           ├─5099 /usr/bin/php-cgi
           ├─5100 /usr/bin/php-cgi
           ├─5101 /usr/bin/php-cgi
           ├─5102 /usr/bin/php-cgi
           ├─5103 /usr/bin/php-cgi
           ├─5104 /usr/bin/php-cgi
           ├─5105 /usr/bin/php-cgi
           ├─5106 /usr/bin/php-cgi
           ├─5107 /usr/bin/php-cgi
           ├─5108 /usr/bin/php-cgi
           ├─5109 /usr/bin/php-cgi
           ├─5110 /usr/bin/php-cgi
           ├─5111 /usr/bin/php-cgi
           ├─5112 /usr/bin/php-cgi
           ├─5113 /usr/bin/php-cgi
           ├─5114 /usr/bin/php-cgi
           ├─5115 /usr/bin/php-cgi
           ├─5116 /usr/bin/php-cgi
           ├─5117 /usr/bin/php-cgi
           ├─5118 /usr/bin/php-cgi
           ├─5119 /usr/bin/php-cgi
           ├─5120 /usr/bin/php-cgi
           ├─5121 /usr/bin/php-cgi
           ├─5122 /usr/bin/php-cgi
           ├─5123 /usr/bin/php-cgi
           ├─5124 /usr/bin/php-cgi
           ├─5125 /usr/bin/php-cgi
           ├─5126 /usr/bin/php-cgi
           ├─5127 /usr/bin/php-cgi
           ├─5128 /usr/bin/php-cgi
           └─5129 /usr/bin/php-cgi

Feb 22 13:39:21 localhost.localdomain systemd[1]: Started Spawn-fcgi startup service by Otus.
```


Пингвин на месте
### Конец решения
### Выполненo базовое задание
