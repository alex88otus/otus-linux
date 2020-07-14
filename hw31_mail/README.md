## Урок №31: **postfix** + **dovecot**
### Решение
#### Настройка
Стенд описан в [Vagrantfile](Vagrantfile)

В комплекте:   
[main.cf](main.cf) - конфиг для **postfix**   
[dovecot.conf](dovecot.conf) - конфиг для **dovecot**

Для получения почты создадим пользователя и настроим ему почтовую папку, что указана в настройках **postfix** и **dovecot**.
```bash
adduser ag
echo "Otus2020" | sudo passwd --stdin ag
mkdir /home/ag/maildir
chown ag:ag /home/ag/maildir
chmod 700 /home/ag/maildir
```
#### Тест отправки почты
С хостовой системы
```bash
telnet 192.168.11.10 25
Trying 192.168.11.10...
Connected to 192.168.11.10.
Escape character is '^]'.
220 mail.666.org ESMTP Postfix
EHLO mail.666.org
250-mail.666.org
250-PIPELINING
250-SIZE 10240000
250-VRFY
250-ETRN
250-ENHANCEDSTATUSCODES
250-8BITMIME
250 DSN
mail from: something@somewhere.local
250 2.1.0 Ok
rcpt to: ag@666.org
250 2.1.5 Ok
data
354 End data with <CR><LF>.<CR><LF>
Subject: ПРИВЕТ
666?
.
250 2.0.0 Ok: queued as 7FC8D4048005
quit
221 2.0.0 Bye
Connection closed by foreign host.
```
Проверим наличие письма на сервере
```bash
[root@mail vagrant]# ll /home/ag/maildir/
total 0
drwx------. 2 ag ag  6 Jul 14 14:33 cur
drwx------. 2 ag ag 49 Jul 14 14:33 new
drwx------. 2 ag ag  6 Jul 14 14:33 tmp
[root@mail vagrant]# ll /home/ag/maildir/new/
total 4
-rw-------. 1 ag ag 284 Jul 14 14:33 1594737228.V801I60931cbM985963.mail
[root@mail vagrant]# cat /home/ag/maildir/new/1594737228.V801I60931cbM985963.mail 
Return-Path: <something@somewhere.local>
X-Original-To: ag@666.org
Delivered-To: ag@666.org
Received: from mail.666.org (666-667 [192.168.11.1])
	by mail.666.org (Postfix) with ESMTP id 7FC8D4048005
	for <ag@666.org>; Tue, 14 Jul 2020 14:32:31 +0000 (UTC)
Subject: ПРИВЕТ

666?
```
Имеется
#### Тест получения почты почтовым клиентом
В качестве клиента используем **Thunderbird**.

Настройки следующие

![123](https://i.imgur.com/si0emxb.png)

И сам пруф

![123](https://i.imgur.com/Ay1nMq8.png)
### Конец решения
### Выполненo