## Урок №12: **selinux**
### Решение
#### Запуск nginx на нестандартном порту
Модификация конфига nginx
```bash
server {
    listen       8888 default_server;
    listen       [::]:8888 default_server;
```
Попытка старта nginx приводит к краху
```bash
May 25 09:40:02 host nginx[3415]: nginx: [emerg] bind() to 0.0.0.0:8888 failed (13: Permission denied)
May 25 09:40:02 host nginx[3415]: nginx: configuration file /etc/nginx/nginx.conf test failed
May 25 09:40:02 host systemd[1]: nginx.service: control process exited, code=exited status=1
May 25 09:40:02 host systemd[1]: Failed to start The nginx HTTP and reverse proxy server.
```
- Решение с помощью setsebool

Ищем нашу ошибку `tail /var/log/audit/audit.log`, интересует *type=AVC*
```bash
type=AVC msg=audit(1590420955.919:68): avc:  denied  { name_bind } for  pid=1048 comm="nginx" src=8888 scontext=system_u:system_r:httpd_t:s0 tcontext=system_u:object_r:unreserved_port_t:s0 tclass=tcp_socket permissive=0
```
Используем **audit2why** для этого сообщения
```bash
[root@host vagrant]# grep 1590420955.919:68 /var/log/audit/audit.log | audit2why 
type=AVC msg=audit(1590420955.919:68): avc:  denied  { name_bind } for  pid=1048 comm="nginx" src=8888 scontext=system_u:system_r:httpd_t:s0 tcontext=system_u:object_r:unreserved_port_t:s0 tclass=tcp_socket permissive=0

	Was caused by:
	The boolean nis_enabled was set incorrectly. 
	Description:
	Allow nis to enabled

	Allow access by executing:
	# setsebool -P nis_enabled 1
```
Видим решение - команда `setsebool nis_enabled 1`
- Добавление нестандартного порта в имеющийся тип

Тип портов для nginx и подобного рода софта это http_port_t, проверим список
```bash
[root@host vagrant]# semanage port -l | grep ^http_port_t
http_port_t                    tcp      80, 81, 443, 488, 8008, 8009, 8443, 9000
```
Добавим нужный порт и проверим
```bash
[root@host vagrant]# semanage port -a -t http_port_t -p tcp 8888
[root@host vagrant]# semanage port -l | grep ^http_port_t
http_port_t                    tcp      8888, 80, 81, 443, 488, 8008, 8009, 8443, 9000
```
nginx работает.
- Формирование и установка модуля SELinux

Один раз неудачно запускаем nginx и скармливаем audit.log в audit2allow
```bash
[root@host vagrant]# grep nginx /var/log/audit/audit.log | audit2allow -m nginx

module nginx 1.0;

require {
	type httpd_t;
	type unreserved_port_t;
	class tcp_socket name_bind;
}

#============= httpd_t ==============

#!!!! This avc can be allowed using the boolean 'nis_enabled'
allow httpd_t unreserved_port_t:tcp_socket name_bind;
```
Создаем модуль, активируем
```bash
[root@host vagrant]# grep nginx /var/log/audit/audit.log | audit2allow -M nginx
******************** IMPORTANT ***********************
To make this policy package active, execute:

semodule -i nginx.pp

[root@host vagrant]# semodule -i nginx.pp
```
Проверяем
```bash
[root@host vagrant]# semodule -l | grep nginx
nginx	1.0
```
nginx работает.
#### Обеспечить работоспособность bind при включенном selinux.
Проверим обновление зоны с клиента
```bash
[vagrant@client ~]$ nsupdate -k /etc/named.zonetransfer.key
> server 192.168.50.10
> zone ddns.lab
> update add www.ddns.lab. 60 A 192.168.50.15
> send
update failed: SERVFAIL
```
Ошибка, ищем в `/var/log/audit/audit.log`
```bash
type=AVC msg=audit(1590429173.674:1829): avc:  denied  { create } for  pid=5118 comm="isc-worker0000" name="named.ddns.lab.view1.jnl" scontext=system_u:system_r:named_t:s0 tcontext=system_u:object_r:etc_t:s0 tclass=file permissive=0
```
Проблема заключается в том что процессу с контекстом *named_t* запрещено записывать файлы в каталоги (конкретно `/etc/named/`) с контекстом *etc_t*.
Предложу 3 варианта решения:
- Сделать процесс с контекстом *named_t* разрешенным (permissive) в SELinux.

Делается командой `semanage permissive -a named_t`. 
Это аналогично отключению SELinux для данного вида процессов по этому не интересен.
- Разрешить для *named_t* запись файлов в каталоги с контекстом *etc_t*

Делается созданием и включением модуля SELinux командой audit2allow.
Вывод для понимания того что разрешаем:
```bash
[root@ns01 vagrant]# grep 1590429173.674:1829 /var/log/audit/audit.log | audit2allow


#============= named_t ==============

#!!!! WARNING: 'etc_t' is a base type.
allow named_t etc_t:file create;
```
Данный способ дает SELinux-права записывать файлы в весь каталог `/etc`.
Настолько "полные" права нам тоже не интересны.
- Сменить файловый контекст на каталоге `/etc/named`

Существует файловый контекст *named_tmp_t* позволяющий процессу с контекстом *named_t* создавать временные файлы в каталоге.
Это наш вариант ибо не привносит каких либо глобальных изменений в SELinux.
При обновлении динамической зоны файлы создаются в каталоге `/etc/named/dynamic/`, для него и поменяем контекст
```bash
[root@ns01 named]# semanage fcontext -a -t named_tmp_t /etc/named/dynamic
[root@ns01 named]# restorecon -v -R /etc/named/dynamic/
restorecon reset /etc/named/dynamic context unconfined_u:object_r:etc_t:s0->unconfined_u:object_r:named_tmp_t:s0
```
Параметры остаются и при перезагрузке
```bash
[root@ns01 vagrant]# semanage fcontext -l -C
SELinux fcontext                                   type               Context

/etc/named/dynamic                                 all files          system_u:object_r:named_tmp_t:s0 
```
Сам каталог выглядит вот так
```bash
[root@ns01 vagrant]# ls -laZ /etc/named/dynamic/
drw-rwx---. root  named unconfined_u:object_r:named_tmp_t:s0 .
drw-rwx---. root  named system_u:object_r:etc_t:s0       ..
-rw-rw----. named named system_u:object_r:etc_t:s0       named.ddns.lab
-rw-rw----. named named system_u:object_r:etc_t:s0       named.ddns.lab.view1
-rw-r--r--. named named system_u:object_r:named_tmp_t:s0 named.ddns.lab.view1.jnl
```
Изменения в тестовом стенде - в провижнинге добавляем 2 таска для ns01
```yaml
  - name: set SELinux fcontext for directory
    command: semanage fcontext -a -t named_tmp_t /etc/named/dynamic
  - name: enable new fcontext
    command: restorecon -v -R /etc/named/dynamic
```
Проверяем
```bash
[vagrant@client ~]$ nsupdate -k /etc/named.zonetransfer.key
> server 192.168.50.10
> zone ddns.lab
> update add www.ddns.lab. 60 A 192.168.50.15
> send
> quit
[vagrant@client ~]$ dig @192.168.50.10 www.ddns.lab +short
192.168.50.15
```
Работает.
### Конец решения
### Выполненo все