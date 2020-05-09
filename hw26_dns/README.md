## Урок №26: dns
### bind9
#### Изменения
В [Vagrantfile](Vagrantfile) добавлен client2 c ip 192.168.50.20.

[named.dns.lab.1](provisioning/named.dns.lab.1) и [named.dns.lab.1.rev](provisioning/named.dns.lab.1.rev) - для view "client1"  
[named.dns.lab.2](provisioning/named.dns.lab.2) и [named.dns.lab.2.rev](provisioning/named.dns.lab.2.rev) - для view "client2"  
[named.newdns.lab](provisioning/named.newdns.lab) - для view "client1"  
[named.ddns.lab](provisioning/named.ddns.lab) - для всех view  
В эти файлы добавлены записи web1, web2, www в соответствии c view.

Изменены [master-named.conf](provisioning/master-named.conf) и [slave-named.conf](provisioning/slave-named.conf) для реализации функционала SplitDNS.
Трансфер зон для разных view происходит с разными ключами
```bash
key "transfer_client1" {
    algorithm hmac-md5;
    secret "pL/sFrAFneRQ+4FJNP4dL9KiYyoTAV6as9A2JOuMAhQ=";
};
key "transfer_client2" {
    algorithm hmac-md5;
    secret "vqSdy/5UVuJBauhVznAjiw9f4sncIm/dDyFxfeZxQhc=";
};
```
Для работоспособности добавлено:  
на мастер
```bash
view "client1" {
    match-clients { 192.168.50.15; key transfer_client1; !key transfer_client2; };
    allow-transfer { key transfer_client1; };
    //В самих зонах
        also-notify { 192.168.50.11 key transfer_client1; };
};
view "client2" {
    match-clients { 192.168.50.20; !key transfer_client1; key transfer_client2; };
    allow-transfer { key transfer_client2; };
    //В самих зонах
        also-notify { 192.168.50.11 key transfer_client2; };
};
```
на слэйв
```bash
view "client1" {
    match-clients { 192.168.50.15; key transfer_client1; !key transfer_client2; };
    //В самих зонах
        masters { 192.168.50.10 key transfer_client1; };
};
view "client2" {
    match-clients { 192.168.50.20; !key transfer_client1; key transfer_client2; };
    //В самих зонах
        masters { 192.168.50.10 key transfer_client2; };
};
```
В [playbook.yml](provisioning/playbook.yml) добавлена таска 
```yaml
    command: chcon -R -t named_tmp_t /etc/named
```
для корректного фуекционирования bind c selinux.
#### Проверка
`vagrant up` все запустит и сконфигурирует.  
Проверяем на client
```bash
[vagrant@client ~]$ dig @192.168.50.10 web1.dns.lab +short
192.168.50.15
[vagrant@client ~]$ dig @192.168.50.10 web2.dns.lab +short
[vagrant@client ~]$ dig @192.168.50.10 www.newdns.lab +short
192.168.50.15
192.168.50.20
[vagrant@client ~]$ dig @192.168.50.11 web1.dns.lab +short
192.168.50.15
[vagrant@client ~]$ dig @192.168.50.11 web2.dns.lab +short
[vagrant@client ~]$ dig @192.168.50.11 www.newdns.lab +short
192.168.50.20
192.168.50.15
```
Проверяем на client2
```bash
[vagrant@client2 ~]$ dig @192.168.50.10 web1.dns.lab +short
192.168.50.15
[vagrant@client2 ~]$ dig @192.168.50.10 web2.dns.lab +short
192.168.50.20
[vagrant@client2 ~]$ dig @192.168.50.10 www.newdns.lab +short
[vagrant@client2 ~]$ dig @192.168.50.11 web1.dns.lab +short
192.168.50.15
[vagrant@client2 ~]$ dig @192.168.50.11 web2.dns.lab +short
192.168.50.20
[vagrant@client2 ~]$ dig @192.168.50.11 www.newdns.lab +short
```
Добавляем запись в зону ddns.lab
```bash
[vagrant@client ~]$ nsupdate -y transfer_client1:pL/sFrAFneRQ+4FJNP4dL9KiYyoTAV6as9A2JOuMAhQ=
> server 192.168.50.10
> zone ddns.lab
> update add www.ddns.lab. 60 A 192.168.50.15
> send
```
Видим обновления на слэйве
```bash
09-May-2020 18:56:03.115 client @0x7fbf1c5e72c0 192.168.50.10#45462/key transfer_client1: view client1: received notify for zone 'ddns.lab': TSIG 'transfer_client1'
09-May-2020 18:56:03.115 zone ddns.lab/IN/client1: notify from 192.168.50.10#45462: serial 2711201408
09-May-2020 18:56:03.123 zone ddns.lab/IN/client1: Transfer started.
09-May-2020 18:56:03.124 transfer of 'ddns.lab/IN/client1' from 192.168.50.10#53: connected using 192.168.50.11#42576 TSIG transfer_client1
09-May-2020 18:56:03.126 zone ddns.lab/IN/client1: transferred serial 2711201408: TSIG 'transfer_client1'
09-May-2020 18:56:03.126 transfer of 'ddns.lab/IN/client1' from 192.168.50.10#53: Transfer status: success
09-May-2020 18:56:03.126 transfer of 'ddns.lab/IN/client1' from 192.168.50.10#53: Transfer completed: 1 messages, 5 records, 290 bytes, 0.002 secs (145000 bytes/sec)
```
Проверяем с клиентов
```bash
[vagrant@client ~]$ dig @192.168.50.10 www.ddns.lab +short
192.168.50.15
[vagrant@client ~]$ dig @192.168.50.11 www.ddns.lab +short
192.168.50.15
[vagrant@client2 ~]$ dig @192.168.50.10 www.ddns.lab +short
192.168.50.15
[vagrant@client2 ~]$ dig @192.168.50.11 www.ddns.lab +short
192.168.50.15
```
Работает.
### Конец решения
### Выполненo + "со звездой"
