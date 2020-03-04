## Урок №7: RPM
### Решение
#### 0. Создаем VM
```bash
vagrant init centos/7
```
[Vagrantfile](Vagrantfile) изменен для провижнинга последующими командами
#### 1. Сборка своего rpm-пакета NGINX
Установка и скачивание необходимых пакетов
```bash
yum install -y redhat-lsb-core wget rpmdevtools rpm-build createrepo yum-utils gcc
wget http://nginx.org/packages/centos/7/SRPMS/nginx-1.16.1-1.el7.ngx.src.rpm
wget https://www.openssl.org/source/latest.tar.gz
```
Разархивируем сорсы **openssl**, установим сорсы **nginx** в домашнюю директорию 
```bash
tar -xf latest.tar.gz
rpm -i nginx-1.16.1-1.el7.ngx.src.rpm
```
Установим необходимые зависимости для сборки **nginx** и соберем его с подключенным **openssl** последней версии
```bash
yum-builddep -y rpmbuild/SPECS/nginx.spec
sed -i 's/with-debug/with-openssl=\/root\/openssl-1.1.1d/' rpmbuild/SPECS/nginx.spec
rpmbuild -bb rpmbuild/SPECS/nginx.spec
```
 Вывод `rpmbuild`
```bash
Wrote: /root/rpmbuild/RPMS/x86_64/nginx-1.16.1-1.el7.ngx.x86_64.rpm
Wrote: /root/rpmbuild/RPMS/x86_64/nginx-debuginfo-1.16.1-1.el7.ngx.x86_64.rpm
Executing(%clean): /bin/sh -e /var/tmp/rpm-tmp.qIXs9U
+ umask 022
+ cd /root/rpmbuild/BUILD
+ cd nginx-1.16.1
+ /usr/bin/rm -rf /root/rpmbuild/BUILDROOT/nginx-1.16.1-1.el7.ngx.x86_64
+ exit 0
```
Проверим
```bash
[root@localhost ~]# ll rpmbuild/RPMS/x86_64/
total 3800
-rw-r--r--. 1 root root 1984996 мар  4 19:22 nginx-1.16.1-1.el7.ngx.x86_64.rpm
-rw-r--r--. 1 root root 1902680 мар  4 19:22 nginx-debuginfo-1.16.1-1.el7.ngx.x86_64.rpm
```
Установим командой `yum localinstall -y rpmbuild/RPMS/x86_64/nginx-1.16.1-1.el7.ngx.x86_64.rpm` и стартанем
```bash
[root@localhost ~]# systemctl start nginx
[root@localhost ~]# systemctl status nginx
● nginx.service - nginx - high performance web server
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; vendor preset: disabled)
   Active: active (running) since Ср 2020-03-04 20:16:48 UTC; 8s ago
     Docs: http://nginx.org/en/docs/
  Process: 18337 ExecStart=/usr/sbin/nginx -c /etc/nginx/nginx.conf (code=exited, status=0/SUCCESS)
 Main PID: 18338 (nginx)
   CGroup: /system.slice/nginx.service
           ├─18338 nginx: master process /usr/sbin/nginx -c /etc/nginx/nginx.conf
           └─18339 nginx: worker process

мар 04 20:16:48 localhost.localdomain systemd[1]: Starting nginx - high performance web server...
мар 04 20:16:48 localhost.localdomain systemd[1]: Started nginx - high performance web server.
```
#### 2. Создание своего репозитория
Создадим папку в дефолтной корневой директории вебсервера, скопируем туда наш **nginx**
и последний **percona-release**
```bash
mkdir /usr/share/nginx/html/repo
cp rpmbuild/RPMS/x86_64/nginx-1.16.1-1.el7.ngx.x86_64.rpm /usr/share/nginx/html/repo
wget https://www.percona.com/redir/downloads/percona-release/redhat/percona-release-1.0-15.noarch.rpm -O /usr/share/nginx/html/repo/percona-release-1.0-15.noarch.rpm
```
Создадим репозиторий
```bash
[root@localhost ~]# createrepo /usr/share/nginx/html/repo/
Spawning worker 0 with 1 pkgs
Spawning worker 1 with 1 pkgs
Workers Finished
Saving Primary metadata
Saving file lists metadata
Saving other metadata
Generating sqlite DBs
Sqlite DBs complete
```
Правка конфигурационного файла для доступа к подкаталогам
```bash
sed -i '/index  index.html/a \\tautoindex on;' /etc/nginx/conf.d/default.conf
```
Тест конфигурации и перезапуск
```bash
[root@localhost ~]# nginx -t
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
[root@localhost ~]# nginx -s reload
```
Смотрим - всё на месте
```bash
[root@localhost html]# curl localhost/repo/
<html>
<head><title>Index of /repo/</title></head>
<body>
<h1>Index of /repo/</h1><hr><pre><a href="../">../</a>
<a href="repodata/">repodata/</a>                                          04-Mar-2020 20:51                   -
<a href="nginx-1.16.1-1.el7.ngx.x86_64.rpm">nginx-1.16.1-1.el7.ngx.x86_64.rpm</a>                  04-Mar-2020 20:19             1984996
<a href="percona-release-1.0-15.noarch.rpm">percona-release-1.0-15.noarch.rpm</a>                  02-Mar-2020 15:26               17424
</pre><hr></body>
</html>
```
Создание файла репозитория
```bash
cat >> /etc/yum.repos.d/otus.repo << EOF
[otus]
name=otus-linux
baseurl=http://localhost/repo
gpgcheck=0
enabled=1
EOF
```
Проверка
```bash
[root@localhost html]# yum repolist enabled | grep otus
otus                                otus-linux                                 2
[root@localhost html]# yum list all | grep otus
percona-release.noarch                      1.0-15                     otus     
[root@localhost html]# yum repoinfo otus
Loaded plugins: fastestmirror
Loading mirror speeds from cached hostfile
 * base: mirror.ni.net.tr
 * extras: centos.turhost.com
 * updates: mirror.dgn.net.tr
Repo-id      : otus
Repo-name    : otus-linux
Repo-status  : enabled
Repo-revision: 1583355107
Repo-updated : Wed Mar  4 20:51:47 2020
Repo-pkgs    : 2
Repo-size    : 1.9 M
Repo-baseurl : http://localhost/repo/
Repo-expire  : 21 600 second(s) (last: Wed Mar  4 21:36:29 2020)
  Filter     : read-only:present
Repo-filename: /etc/yum.repos.d/otus.repo

repolist: 2
```
**nginx** не отображается т.к. он же уже установлен из другого места.
### Конец решения
### Выполненo базовое задание