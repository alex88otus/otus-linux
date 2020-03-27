## Урок №14: AAA
### Решение
#### Работа с базовыми утилитами
Создаем пользователей
```bash
useradd -m -s /bin/bash user1
useradd -m -s /bin/bash user2 
```
Смотрим их id в `/etc/passwd`
```bash
user1:x:1001:1001::/home/user1:/bin/bash
user2:x:1002:1002::/home/user2:/bin/bash
```
Опции -m и -s означают следующее
```bash
-m, --create-home             create the user's home directory
-s, --shell SHELL             login shell of the new account
```
Создаем группу admins и добавляем туда пользователей
```bash
groupadd admins
usermod -a -G admins user1
usermod -a -G admins user2
```
Проверяем
```bash
[root@hostname ~]# id user1 && id user2
uid=1001(user1) gid=1001(user1) groups=1001(user1),1003(admins)
uid=1002(user2) gid=1002(user2) groups=1002(user2),1003(admins)
```
Делаем группу admins основной для user1
```bash
[root@hostname ~]# usermod -g admins user1
[root@hostname ~]# id user1
uid=1001(user1) gid=1003(admins) groups=1003(admins),1001(user1)
```
Создаем каталог от рута и даем права группе admins туда писать
```bash
mkdir /opt/upload
chmod 770 /opt/upload
chgrp admins /opt/upload
```
Получаем
```bash
drwxrwx---. 2 root admins 32 Mar 26 12:56 /opt/upload/
```
770 в данном случае означают полные права доступа для пользователя root, полные права для группы admins и отсутствие прав для всех остальных.

Созжаем файлы следующим образом
```bash
[root@hostname ~]# sudo -u user1 touch /opt/upload/test1
[root@hostname ~]# sudo -u user2 touch /opt/upload/test2
[root@hostname ~]# su - user2
Last login: Thu Mar 26 13:43:10 UTC 2020 on pts/0
[user2@hostname ~]$ newgrp admins
[user2@hostname ~]$ touch /opt/upload/test3
```
Проверяем
```bash
[root@hostname ~]# ll /opt/upload/
total 0
-rw-r--r--. 1 user1 admins 0 Mar 26 13:44 test1
-rw-r--r--. 1 user2 user2  0 Mar 26 13:45 test2
-rw-r--r--. 1 user2 admins 0 Mar 26 13:46 test3
```
Создаем третьего пользователя, пробуем писать в наш католог
```bash
[root@hostname ~]# useradd -m -s /bin/bash user3
[root@hostname ~]# sudo -u user3 touch /opt/upload/test4
touch: cannot touch ‘/opt/upload/test4’: Permission denied
```
`getfacl /opt/upload`
```bash
getfacl: Removing leading '/' from absolute path names
# file: opt/upload
# owner: root
# group: admins
user::rwx
group::rwx
other::---
```
Добавляем полные права на каталог для user3 командой `setfacl -m u:user3:rwx /opt/upload` и пробуем писать
```bash
[root@hostname ~]# sudo -u user3 touch /opt/upload/test4
[root@hostname ~]# ll /opt/upload/test4
-rw-r--r--. 1 user3 user3 0 Mar 26 14:03 /opt/upload/test4
```
`ll /opt/upload/`
```bash
total 0
-rw-r--r--. 1 user1 admins 0 Mar 26 13:44 test1
-rw-r--r--. 1 user2 user2  0 Mar 26 13:45 test2
-rw-r--r--. 1 user2 admins 0 Mar 26 13:46 test3
-rw-r--r--. 1 user3 user3  0 Mar 26 14:03 test4
```
`getfacl /opt/upload/`
```bash
getfacl: Removing leading '/' from absolute path names
# file: opt/upload/
# owner: root
# group: admins
user::rwx
user:user3:rwx
group::rwx
mask::rwx
other::---
```
Установим GUID флаг на директорию `/opt/uploads`
```bash
[root@hostname ~]# sudo -u user3 touch /opt/upload/test5
[root@hostname ~]# ll /opt/upload/test5
-rw-r--r--. 1 user3 admins 0 Mar 26 15:36 /opt/upload/test5
```
Группа изменилась из-за вышеустановленного флага. Все файлы созданные в данном каталоге буду наследовать права группы этого каталога.

`ll /opt/upload/`
```bash
total 0
-rw-r--r--. 1 user1 admins 0 Mar 26 13:44 test1
-rw-r--r--. 1 user2 user2  0 Mar 26 13:45 test2
-rw-r--r--. 1 user2 admins 0 Mar 26 13:46 test3
-rw-r--r--. 1 user3 user3  0 Mar 26 14:03 test4
-rw-r--r--. 1 user3 admins 0 Mar 26 15:36 test5
```
Попробуем прочитать `/etc/shadow` пользователем user3
```bash
[root@hostname ~]# sudo -u user3 cat /etc/shadow
cat: /etc/shadow: Permission denied
```
Установим SUID флаг на исполняемый файл и пробуем ещё раз
```bash
[root@hostname ~]# chmod u+s /bin/cat
[root@hostname ~]# sudo -u user3 cat /etc/shadow
root:$1$QDyPlph/$oaAX/xNRf3aiW3l27NIUA/::0:99999:7:::
```
Данный флаг на исполняемых файлах позволяет запускать процесс от имени владельца файла.
Сменим владельца `/opt/uploads` на user3 и добавим sticky bit на директорию
```bash
chown user3 /opt/upload
chmod +t /opt/upload
```
Попробуем создать файл пользователем user1 и удалить владельцем директории
```bash
[root@hostname ~]# sudo -u user1 touch /opt/upload/test6
[root@hostname ~]# ll /opt/upload/test6
-rw-r--r--. 1 user1 admins 0 Mar 26 16:01 /opt/upload/test6
[root@hostname ~]# sudo -u user3 rm -f /opt/upload/test6
```
Файл удалился и это нормально ведь user3 владелец каталога с rwx правами.
Создадим теперь файл от user1 и удалим его пользователем user1.
```bash
[root@hostname ~]# sudo -u user1 touch /opt/upload/test7
[root@hostname ~]# sudo -u user1 rm -f /opt/upload/test7
```
Работает, а что-то могло пойти не так? (всё по методичке)

Попробуем из под user3 выполнить `sudo ls -l /root`
```bash
[root@hostname ~]# su - user3
Last login: Thu Mar 26 17:10:42 UTC 2020 on pts/0
[user3@hostname ~]$ sudo ls -l /root
[sudo] password for user3: 
user3 is not in the sudoers file.  This incident will be reported.
```
У пользователя нет прав на запуск sudo, дадим ему права на запуск sudo для утилиты ls без ввода пароля. Создадим файл `/etc/sudoers.d/user3` cо следующим содержанием
```bash
user3	ALL=NOPASSWD:/bin/ls
```
В результате работает
```bash
[root@hostname ~]# su - user3
Last login: Thu Mar 26 17:16:30 UTC 2020 on pts/0
[user3@hostname ~]$ sudo ls -l /root
total 16
-rw-------. 1 root root 5570 Jun  1  2019 anaconda-ks.cfg
-rw-------. 1 root root 5300 Jun  1  2019 original-ks.cfg
```
А для разрешения группе admins запускать любые команды от любого пользователя добавим в файл `/etc/sudoers.d/admins` такое содержимое
```bash
%admins	ALL=(ALL)   ALL
```
Проверим.
```bash
[root@hostname ~]# su - user1
Last login: Thu Mar 26 18:09:58 UTC 2020 on pts/0
[user1@hostname ~]$ sudo touch /root/123
[sudo] password for user1: 
[user1@hostname ~]$ ls -l /root/123
ls: cannot access /root/123: Permission denied
[user1@hostname ~]$ sudo ls -l /root/123
-rw-r--r--. 1 root root 0 Mar 26 18:11 /root/123
```
Работает, пароль запрашивает
#### Работа с PAM
Необходимо решить задачу по ограничению доступа пользователей в систему по ssh. Это будут пользователи: “day“, “night”, “friday”. 
Введем для них соответственно ограничения: ”day” имеет удаленный доступ каждый день с 8 до 20, “night” - с 20 до 8, “friday” - в любое время, если сегодня пятница.

Создаем пользователей
```bash
useradd day && \
useradd night && \
useradd friday
```
Ставим пароли
```bash
echo "Otus2019" | sudo passwd --stdin day && \
echo "Otus2019" | sudo passwd --stdin night && \
echo "Otus2019" | sudo passwd --stdin friday
```
Разрешаем вход с паролем через ssh
```bash
sed -i 's/^PasswordAuthentication.*$/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
systemctl restart sshd.service
```
Добавляем временные рамки для пользователей в `/etc/security/time.conf`
```bash
echo '*;*;day;Al0800-2000
*;*;night;!Al0800-2000
*;*;friday;Fr0000-2400
' >>/etc/security/time.conf
```
Подключаем модуль времени в настройках PAM для sshd
```bash
sed -i '/pam_nologin/a account\t   required\tpam_time.so' /etc/pam.d/sshd
```
Время на хосте - 19:52, не пятница; проверяем
```bash
ssh day@192.168.56.101
day@192.168.56.101's password: 
[day@hostname ~]$ exit
logout
Connection to 192.168.56.101 closed.

ssh night@192.168.56.101
night@192.168.56.101's password: 
Connection closed by 192.168.56.101 port 22

ssh friday@192.168.56.101
friday@192.168.56.101's password: 
Connection closed by 192.168.56.101 port 22
```
Работает.

Рассмотрим другой вариант решения задачи - при помощи pam_exec и своего скрипта [test_login.sh](test_login.sh)

Заменим настройки в файле `/etc/pam.d/sshd`, подключим модуль pam_exec
```bash
sed -ri 's".+pam_time.so"account\t   required\tpam_exec.so /usr/local/bin/test_login.sh"' /etc/pam.d/sshd
```
Скопируем скрипт и сделаем исполняемым
```bash
cp /vagrant/test_login.sh /usr/local/bin/
chmod +x /usr/local/bin/test_login.sh
```
Проверяем, время 22:20, не пятница
```bash
ssh day@192.168.56.101
day@192.168.56.101's password: 
/usr/local/bin/test_login.sh failed: exit code 1
Connection closed by 192.168.56.101 port 22

ssh night@192.168.56.101
night@192.168.56.101's password: 
[night@hostname ~]$ exit
logout
Connection to 192.168.56.101 closed.

ssh friday@192.168.56.101
friday@192.168.56.101's password: 
/usr/local/bin/test_login.sh failed: exit code 1
Connection closed by 192.168.56.101 port 22
```
Работает.

Еще 1 вариант решения - модуль pam_script и тот же скрипт - заставить работать не получилось.

Рассмотрим модуль pam-cat для PAM.

Для этого установим доп пакет `yum install -y nmap-ncat`, попробуем под пользователес day
```bash
[day@hostname ~]$ ncat -l -p 80
Ncat: bind to :::80: Permission denied. QUITTING.
```
Попробуем дать права на открытие портов пользователю, для начала отключим SELinux командой `setenforce 0`. Добавим обработку модуля в файл `/etc/pam.d/sshd`
```bash
sed -ir '/auth.+postlogin/a auth\t   required\tpam_cap.so' /etc/pam.d/sshd
```
Добавим необходимый конфиг
```bash
echo 'cap_net_bind_service day' >/etc/security/capability.conf
```
Добавим разрешения и для нужной программы
```bash
setcap cap_net_bind_service=ei /usr/bin/ncat
```
Перелогинемся пользователем day и проверим права
```bash
[day@hostname ~]$ capsh --print
Current: = cap_net_bind_service+i
```
Проверим предварительно запустив `ncat` ot day
```bash
[root@hostname dev]# echo '123123' > /dev/tcp/localhost/80

[day@hostname ~]$ ncat -l -p 80
123123
```
Сработает также с любым адресом из 127.0.0.0/8

Попробуем предоставить пользователю day права на `sudo` без запроса пароля. Для этого создадим файлик `/etc/sudoers.d/day` из под root
```bash
echo 'day ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/day
```
Проверика
```bash
[day@hostname ~]$ sudo -i
[root@hostname ~]# 
```
Ну естественно.
#### Домашка с PAM
Запретить всем пользователям, кроме группы admin логин в выходные (суббота и воскресенье), без учета праздников.

ОК, реалезуем с помощью скрипта [mylogin.sh](mylogin.sh) и модуля pam_exec. Создадим пользователей и группу, user1 добавим в группу admin
```bash
[root@hostname ~]# useradd -m -s /bin/bash user1
[root@hostname ~]# useradd -m -s /bin/bash user2
[root@hostname ~]# groupadd admin
[root@hostname ~]# usermod -a -G admin user1
[root@hostname ~]# id user1 && id user2
uid=1001(user1) gid=1001(user1) groups=1001(user1),1003(admin)
uid=1002(user2) gid=1002(user2) groups=1002(user2)
```
Присвоим пароли
```bash
[root@hostname ~]# echo "Otus2019" | sudo passwd --stdin user1
Changing password for user user1.
passwd: all authentication tokens updated successfully.
[root@hostname ~]# echo "Otus2019" | sudo passwd --stdin user2
Changing password for user user2.
passwd: all authentication tokens updated successfully.
```
Включим возможность подключения по ssh с паролем
```bash
sed -i 's/^PasswordAuthentication.*$/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
systemctl restart sshd.service
```
Проверим
```bash
ssh user1@192.168.56.101
user1@192.168.56.101's password: 
[user1@hostname ~]$ exit
logout
Connection to 192.168.56.101 closed.

ssh user2@192.168.56.101
user2@192.168.56.101's password: 
[user2@hostname ~]$ exit
logout
Connection to 192.168.56.101 closed.
```
Сделаем скрипт исполняемым, скопируем в `/usr/local/bin/`, добавим настройки в `/etc/pam.d/sshd`
```bash
chmod +x /vagrant/mylogin.sh
cp /vagrant/mylogin.sh /usr/local/bin/
sed -i '/pam_nologin/a account\t   required\tpam_exec.so /vagrant/mylogin.sh' /etc/pam.d/sshd
```
Поставим дату на воскресенье
```bash
[root@hostname ~]# date -s Sun
Sun Mar 29 00:00:00 UTC 2020
```
Проверяем
```bash
ssh user1@192.168.56.101
user1@192.168.56.101's password: 
[user1@hostname ~]$ exit
logout
Connection to 192.168.56.101 closed.

ssh user2@192.168.56.101
user2@192.168.56.101's password: 
/usr/local/bin/mylogin.sh failed: exit code 1
Connection closed by 192.168.56.101 port 22
```
Работает.
Дать конкретному пользователю права работать с докером
и возможность рестартить докер сервис.

Для использования docker непривелигерованным пользователем достаточно создать группу docker и и добавить в нее пользователя.
Попробуем на user2
```bash
[root@hostname ~]# groupadd docker
[root@hostname ~]# usermod -aG docker user2
[root@hostname ~]# su - user2
[user2@hostname ~]$ id
uid=1002(user2) gid=1002(user2) groups=1002(user2),1004(docker) context=unconfined_u:unconfined_r:unconfined_t:s0-s0:c0.c1023
[user2@hostname ~]$ docker run hello-world
Unable to find image 'hello-world:latest' locally
Trying to pull repository docker.io/library/hello-world ... 
latest: Pulling from docker.io/library/hello-world
1b930d010525: Pull complete 
Digest: sha256:f9dfddf63636d84ef479d645ab5885156ae030f611a56f3a7ac7f2fdd86d7e4e
Status: Downloaded newer image for docker.io/hello-world:latest

Hello from Docker!
```
А рестартить докер сервис утилитой `systemctl` без `sudo` не получится, просто добавим пользователя в sudoers только для некоторых команд.
Создадим файл `/etc/sudoers.d/user2` и добавим в него следующее содержимое
```bash
Cmnd_Alias DOCKER_1 = /usr/bin/systemctl stop docker, /usr/bin/systemctl start docker, /usr/bin/systemctl restart docker

user2 ALL= NOPASSWD: DOCKER_1
```
После добавления у пользователя user2 появится возможность перезапускать только докер сервис и без ввода пароля.

### Конец решения
### Выполненo дз и дз со *