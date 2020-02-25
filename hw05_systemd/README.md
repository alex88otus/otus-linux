## Урок №5: **sistemd**
### Решение
#### 0. Создаем VM
```bash
vagrant init centos/7
```
#### 1. Написать сервис **watchlog**, запускаемый по расписанию
Необходимые файлы расположем в подкаталоге рабочего каталога [watchlog](watchlog), посмотрим что внутри

cat [etc/sysconfig/watchlog](watchlog/etc/sysconfig/watchlog)
```bash
# Configuration file for my watchdog service
# Place it to /etc/sysconfig
# File and word in that file that we will be monit
WORD="ALERT"
LOG=/var/log/watchlog.log
```
cat [etc/systemd/system/watchlog.service](watchlog/etc/systemd/system/watchlog.service)
```bash
[Unit]
Description=My watchlog service
[Service]
Type=oneshot
EnvironmentFile=/etc/sysconfig/watchlog
ExecStart=/opt/watchlog.sh $WORD $LOG
```
cat [etc/systemd/system/watchlog.timer](watchlog/etc/systemd/system/watchlog.timer)
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
cat [opt/watchlog.sh](watchlog/opt/watchlog.sh)
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
cat [var/log/watchlog.log](watchlog/var/log/watchlog.log)
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
#### 2. Из репозитория epel установить spawn-fcgi, создать unit-файл
Необходимые файлы расположем в подкаталоге рабочего каталога [spawn-fcgi](spawn-fcgi), посмотрим что внутри

cat [etc/sysconfig/spawn-fcgi](spawn-fcgi/etc/sysconfig/spawn-fcgi)
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
cat [etc/systemd/system/spawn-fcgi.service](spawn-fcgi/etc/systemd/system/spawn-fcgi.service)
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
Устанавливаем необходимые пакеты
```bash
yum install epel-release -y && yum install spawn-fcgi php php-cli mod_fcgid httpd -y
```
Копируем *с заменой* необходимые файлы
```bash
yes | cp -fr /vagrant/spawn-fcgi/* /
```
Запускаем, проверяем работу
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
Работает корректно
#### 3. Дополнить unit-файл httpd возможностью запустить ещё 2 инстанса сервера с разными конфигурационными файлами
Необходимые файлы расположем в подкаталоге рабочего каталога [httpd-new](httpd-new), при старте VM эти файлы копируются с директорию `/vagrant`
```bash
➜  httpd-new git:(master) ✗ tree
.
├── etc
│   ├── httpd
│   │   └── conf
│   │       ├── 1.conf
│   │       └── 2.conf
│   └── sysconfig
│       ├── httpd-1
│       └── httpd-2
└── usr
    └── lib
        └── systemd
            └── system
                └── httpd@.service

8 directories, 5 files
```
cat [usr/lib/systemd/system/httpd@.service](httpd-new/usr/lib/systemd/system/httpd@.service)
```bash
[Unit]
Description=The Apache HTTP Server
After=network.target remote-fs.target nss-lookup.target
Documentation=man:httpd(8)
Documentation=man:apachectl(8)

[Service]
Type=notify
EnvironmentFile=/etc/sysconfig/httpd-%I
ExecStart=/usr/sbin/httpd $OPTIONS -DFOREGROUND
ExecReload=/usr/sbin/httpd $OPTIONS -k graceful
ExecStop=/bin/kill -WINCH ${MAINPID}
# We want systemd to give httpd some time to finish gracefully, but still want
# it to kill httpd after TimeoutStopSec if something went wrong during the
# graceful stop. Normally, Systemd sends SIGTERM signal right after the
# ExecStop, which would kill httpd. We are sending useless SIGCONT here to give
# httpd time to finish.
KillSignal=SIGCONT
PrivateTmp=true

[Install]
WantedBy=multi-user.target
```
Посмотрим изменения в файлах окружения и конфигурационных файлах
```bash
➜  httpd-new git:(master) ✗ grep OPTIONS= etc/sysconfig/httpd-*
etc/sysconfig/httpd-1:OPTIONS=-f conf/1.conf
etc/sysconfig/httpd-2:OPTIONS=-f conf/2.conf
➜  httpd-new git:(master) ✗ grep 'Listen 8' etc/httpd/conf/*
etc/httpd/conf/1.conf:Listen 80
etc/httpd/conf/2.conf:Listen 8080
➜  httpd-new git:(master) ✗ grep 'PidFile ' etc/httpd/conf/*
etc/httpd/conf/1.conf:PidFile /var/run/httpd-1.pid
etc/httpd/conf/2.conf:PidFile /var/run/httpd-2.pid
```
Запустим VM, скопируем файлы по своим каталогам, запускаем сервисы
```bash
systemctl start httpd@1 httpd@2
```
Проверяем
```bash
[root@localhost vagrant]# ss -tnulp | grep httpd
tcp    LISTEN     0      128      :::8080                 :::*                   users:(("httpd",pid=3773,fd=4),("httpd",pid=3772,fd=4),("httpd",pid=3771,fd=4),("httpd",pid=3770,fd=4),("httpd",pid=3769,fd=4),("httpd",pid=3768,fd=4))
tcp    LISTEN     0      128      :::80                   :::*                   users:(("httpd",pid=3761,fd=4),("httpd",pid=3760,fd=4),("httpd",pid=3759,fd=4),("httpd",pid=3758,fd=4),("httpd",pid=3757,fd=4),("httpd",pid=3756,fd=4))
[root@localhost vagrant]# systemctl status httpd@1 httpd@2
● httpd@1.service - The Apache HTTP Server
   Loaded: loaded (/usr/lib/systemd/system/httpd@.service; disabled; vendor preset: disabled)
   Active: active (running) since Tue 2020-02-25 10:29:54 UTC; 1min 11s ago
     Docs: man:httpd(8)
           man:apachectl(8)
 Main PID: 3756 (httpd)
   Status: "Total requests: 0; Current requests/sec: 0; Current traffic:   0 B/sec"
   CGroup: /system.slice/system-httpd.slice/httpd@1.service
           ├─3756 /usr/sbin/httpd -f conf/1.conf -DFOREGROUND
           ├─3757 /usr/sbin/httpd -f conf/1.conf -DFOREGROUND
           ├─3758 /usr/sbin/httpd -f conf/1.conf -DFOREGROUND
           ├─3759 /usr/sbin/httpd -f conf/1.conf -DFOREGROUND
           ├─3760 /usr/sbin/httpd -f conf/1.conf -DFOREGROUND
           └─3761 /usr/sbin/httpd -f conf/1.conf -DFOREGROUND

Feb 25 10:29:54 localhost.localdomain systemd[1]: Starting The Apache HTTP Server...
Feb 25 10:29:54 localhost.localdomain httpd[3756]: AH00558: httpd: Could not reliably determine th...age
Feb 25 10:29:54 localhost.localdomain systemd[1]: Started The Apache HTTP Server.

● httpd@2.service - The Apache HTTP Server
   Loaded: loaded (/usr/lib/systemd/system/httpd@.service; disabled; vendor preset: disabled)
   Active: active (running) since Tue 2020-02-25 10:29:56 UTC; 1min 9s ago
     Docs: man:httpd(8)
           man:apachectl(8)
 Main PID: 3768 (httpd)
   Status: "Total requests: 0; Current requests/sec: 0; Current traffic:   0 B/sec"
   CGroup: /system.slice/system-httpd.slice/httpd@2.service
           ├─3768 /usr/sbin/httpd -f conf/2.conf -DFOREGROUND
           ├─3769 /usr/sbin/httpd -f conf/2.conf -DFOREGROUND
           ├─3770 /usr/sbin/httpd -f conf/2.conf -DFOREGROUND
           ├─3771 /usr/sbin/httpd -f conf/2.conf -DFOREGROUND
           ├─3772 /usr/sbin/httpd -f conf/2.conf -DFOREGROUND
           └─3773 /usr/sbin/httpd -f conf/2.conf -DFOREGROUND

Feb 25 10:29:56 localhost.localdomain systemd[1]: Starting The Apache HTTP Server...
Feb 25 10:29:56 localhost.localdomain httpd[3768]: AH00558: httpd: Could not reliably determine th...age
Feb 25 10:29:56 localhost.localdomain systemd[1]: Started The Apache HTTP Server.
Hint: Some lines were ellipsized, use -l to show in full.
```
Оба инстанса httpd запущены
#### 4. Скачать демо-версию Atlassian Jira (в данном случае Jira Service Desk) и переписать основной скрипт запуска на unit-файл.
Установка и настрой производится в автоматическом режиме: [Vagrantfile](Vagrantfile) + подключенный скрипт для провижининга [script.sh](script.sh). Написано по оффициальной докуметации: [Installing Jira applications on Linux from Archive File](https://confluence.atlassian.com/adminjiraserver/installing-jira-applications-on-linux-from-archive-file-938846844.html) и [Run Jira as a systemd service on linux](https://confluence.atlassian.com/jirakb/run-jira-as-a-systemd-service-on-linux-979411854.html).

Разберем работу скрипта.

Установка необходимых пакетов, скачивание Jira, установка
```bash
yum install -y fontconfig java wget
wget https://www.atlassian.com/software/jira/downloads/binary/atlassian-servicedesk-4.7.1.tar.gz
mkdir /opt/atlassian/
tar -xf atlassian-servicedesk-4.7.1.tar.gz
mv atlassian-jira-servicedesk-4.7.1-standalone/ /opt/atlassian/jira/
```
Добавление юзера jira, раздача необходимых прав ему на рабочие каталоги
```bash
useradd jira
chown -R jira /opt/atlassian/jira/
chmod -R u=rwx,go-rwx /opt/atlassian/jira/
mkdir /home/jira/jirasoftware-home
chown -R jira /home/jira/jirasoftware-home
chmod -R u=rwx,go-rwx /home/jira/jirasoftware-home
```
Необходимые фиксы
```bash
sed -i 's/#JIRA_HOME=""/JIRA_HOME="\/home\/jira\/jirasoftware-home"/g' /opt/atlassian/jira/bin/setenv.sh
sed -i 's/16384/4096/g' /opt/atlassian/jira/bin/setenv.sh
```
Создание unit-файла
```bash
touch /lib/systemd/system/jira.service
chmod 664 /lib/systemd/system/jira.service
echo '[Unit] 
Description=Atlassian Jira
After=network.target
[Service] 
Type=forking
User=jira
PIDFile=/opt/atlassian/jira/work/catalina.pid
ExecStart=/opt/atlassian/jira/bin/start-jira.sh
ExecStop=/opt/atlassian/jira/bin/stop-jira.sh
[Install] 
WantedBy=multi-user.target' >> /lib/systemd/system/jira.service
```
Включение, запуск
```bash
systemctl daemon-reload
systemctl enable jira.service
systemctl start jira.service
systemctl status jira.service
```
Фото
![123](https://i.imgur.com/4n5xuLB.png)

### Конец решения
### Выполненo: базовое задание + "со звездочкой"
