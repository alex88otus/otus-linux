## Урок №18: network
### Решение
#### Подготовка
Исправленный [Vagrantfile](Vagrantfile).
Роутеры и centralServer вынесены в отдельную подсеть `192.168.0.0/28`.
На всех тачках отключаем ZEROCONF и IPv6 чтобы не мешалось
```bash
echo "NOZEROCONF=yes" >> /etc/sysconfig/network
echo "NETWORKING_IPV6=no" >> /etc/sysconfig/network
echo "IPV6INIT=no" >> /etc/sysconfig/network
```
Отключаем дефолтный маршрут для интерфейсов с адресами 10.0.0.0/8 (кроме inetRouter)
```bash
echo "DEFROUTE=no" >> /etc/sysconfig/network-scripts/ifcfg-eth0
```
Изменения применяются (почему-то) после двойной перезaгрузки службы network.

На роутерах включаем ip-форвардинг
```bash
sysctl -w net.ipv4.conf.all.forwarding=1
```
Для всей системы добавил только 3 дополнительных маршрута (не включая маршруты по умолчанию).
```bash
ip route add 192.168.0.0/17 via 192.168.255.2 dev eth1
```
для inetRouter.
```bash
ip route add 192.168.1.0/24 via 192.168.0.3 dev eth2
ip route add 192.168.2.0/24 via 192.168.0.4 dev eth2
```
для centralRouter.
#### Схема сети
![123](https://i.imgur.com/18QjE6p.jpg)
#### Расчеты по сетям
#### Сеть **central**
- **routers**
```
Network:   192.168.0.0/28
Netmask:   255.255.255.240
HostMin:   192.168.0.1      centralRouter: eth2
           192.168.0.2      centralServer: eth1
           192.168.0.3      office1Router: eth1
           192.168.0.4      office2Router: eth1
HostMax:   192.168.0.14
Broadcast: 192.168.0.15 
Hosts/Net: 14
```
- **dir-net**     
```
Network:   192.168.0.16/28
Netmask:   255.255.255.240
HostMin:   192.168.0.17     centralRouter: eth3
HostMax:   192.168.0.30
Broadcast: 192.168.0.31
Hosts/Net: 14
```
- **hw-net**
```
Network:   192.168.0.32/27
Netmask:   255.255.255.224
HostMin:   192.168.0.33     centralRouter: eth4
HostMax:   192.168.0.62
Broadcast: 192.168.0.63
Hosts/Net: 30
```
- **wifi-net**
```
Network:   192.168.0.64/26
Netmask:   255.255.255.192
HostMin:   192.168.0.65     centralRouter: eth5
HostMax:   192.168.0.126
Broadcast: 192.168.0.127
Hosts/Net: 62
```
#### Сеть **office1**
- **dev1-net**
```
Network:   192.168.1.0/25
Netmask:   255.255.255.128
HostMin:   192.168.1.1      office1Router: eth2
           192.168.1.2      office1Server: eth1
HostMax:   192.168.1.126
Broadcast: 192.168.1.127
Hosts/Net: 126
```
- **testsrv1-net**
```
Network:   192.168.1.128/26
Netmask:   255.255.255.192
HostMin:   192.168.1.129    office1Router: eth3
HostMax:   192.168.1.190
Broadcast: 192.168.1.191
Hosts/Net: 62
```
- **hw1-net**
```
Network:   192.168.1.192/26
Netmask:   255.255.255.192
HostMin:   192.168.1.193    office1Router: eth4
HostMax:   192.168.1.254
Broadcast: 192.168.1.255
Hosts/Net: 62
```
#### Сеть **office2**
- **dev2-net**
```
Network:   192.168.2.0/26
Netmask:   255.255.255.192
HostMin:   192.168.2.1      office2Router: eth2
           192.168.2.2      office2Server: eth1
HostMax:   192.168.2.62
Broadcast: 192.168.2.63
Hosts/Net: 62
```
- **testsrv2-net**
```
Network:   192.168.2.64/26
Netmask:   255.255.255.192
HostMin:   192.168.2.65     office2Router: eth3
HostMax:   192.168.2.126
Broadcast: 192.168.2.127
Hosts/Net: 62
```
- **mng-net**
```
Network:   192.168.2.128/26
Netmask:   255.255.255.192
HostMin:   192.168.2.129    office2Router: eth4
HostMax:   192.168.2.190
Broadcast: 192.168.2.191
Hosts/Net: 62
```
- **hw2-net**
```
Network:   192.168.2.192/26
Netmask:   255.255.255.192
HostMin:   192.168.2.193    office2Router: eth5
HostMax:   192.168.2.254
Broadcast: 192.168.2.255
Hosts/Net: 62
```
#### Проверка
Запускаем стенд, в 2 потока достаточно
```bash
grep when Vagrantfile | awk -F'"' '{print $2}' | xargs -P2 -I {} vagrant up {}
```
Мануальная проверка показала, что серверы друг друга видят итд итп

[show_routes.sh](show_routes.sh) - скрипт для проверки маршрутов и форвардинга на всех машинах.

Вывод
```
-----------------------------------------------------
  inetRouter
-----------------------------------------------------
192.168.255.0/30 dev eth1  proto kernel  scope link  src 192.168.255.1 
10.0.2.0/24 dev eth0  proto kernel  scope link  src 10.0.2.15 
192.168.0.0/17 via 192.168.255.2 dev eth1 
default via 10.0.2.2 dev eth0 
-----------------------------------------------------
net.ipv4.conf.all.forwarding = 1
-----------------------------------------------------
-----------------------------------------------------
  centralRouter
-----------------------------------------------------
default via 192.168.255.1 dev eth1 proto static metric 101 
10.0.2.0/24 dev eth0 proto kernel scope link src 10.0.2.15 metric 100 
192.168.0.0/28 dev eth2 proto kernel scope link src 192.168.0.1 metric 102 
192.168.0.16/28 dev eth3 proto kernel scope link src 192.168.0.17 metric 103 
192.168.0.32/27 dev eth4 proto kernel scope link src 192.168.0.33 metric 104 
192.168.0.64/26 dev eth5 proto kernel scope link src 192.168.0.65 metric 105 
192.168.1.0/24 via 192.168.0.3 dev eth2 
192.168.2.0/24 via 192.168.0.4 dev eth2 
192.168.255.0/30 dev eth1 proto kernel scope link src 192.168.255.2 metric 101 
-----------------------------------------------------
net.ipv4.conf.all.forwarding = 1
-----------------------------------------------------
-----------------------------------------------------
  office1Router
-----------------------------------------------------
default via 192.168.0.1 dev eth1 proto static metric 101 
10.0.2.0/24 dev eth0 proto kernel scope link src 10.0.2.15 metric 100 
192.168.0.0/28 dev eth1 proto kernel scope link src 192.168.0.3 metric 101 
192.168.1.0/25 dev eth2 proto kernel scope link src 192.168.1.1 metric 102 
192.168.1.128/26 dev eth3 proto kernel scope link src 192.168.1.129 metric 103 
192.168.1.192/26 dev eth4 proto kernel scope link src 192.168.1.193 metric 104 
-----------------------------------------------------
net.ipv4.conf.all.forwarding = 1
-----------------------------------------------------
-----------------------------------------------------
  office2Router
-----------------------------------------------------
default via 192.168.0.1 dev eth1 proto static metric 101 
10.0.2.0/24 dev eth0 proto kernel scope link src 10.0.2.15 metric 100 
192.168.0.0/28 dev eth1 proto kernel scope link src 192.168.0.4 metric 101 
192.168.2.0/26 dev eth2 proto kernel scope link src 192.168.2.1 metric 102 
192.168.2.64/26 dev eth3 proto kernel scope link src 192.168.2.65 metric 103 
192.168.2.128/26 dev eth4 proto kernel scope link src 192.168.2.129 metric 104 
192.168.2.192/26 dev eth5 proto kernel scope link src 192.168.2.193 metric 105 
-----------------------------------------------------
net.ipv4.conf.all.forwarding = 1
-----------------------------------------------------
-----------------------------------------------------
  centralServer
-----------------------------------------------------
default via 192.168.0.1 dev eth1 proto static metric 101 
10.0.2.0/24 dev eth0 proto kernel scope link src 10.0.2.15 metric 100 
192.168.0.0/28 dev eth1 proto kernel scope link src 192.168.0.2 metric 101 
-----------------------------------------------------
net.ipv4.conf.all.forwarding = 0
-----------------------------------------------------
-----------------------------------------------------
  office1Server
-----------------------------------------------------
default via 192.168.1.1 dev eth1 proto static metric 101 
10.0.2.0/24 dev eth0 proto kernel scope link src 10.0.2.15 metric 100 
192.168.1.0/25 dev eth1 proto kernel scope link src 192.168.1.2 metric 101 
-----------------------------------------------------
net.ipv4.conf.all.forwarding = 0
-----------------------------------------------------
-----------------------------------------------------
  office2Server
-----------------------------------------------------
default via 192.168.2.1 dev eth1 proto static metric 101 
10.0.2.0/24 dev eth0 proto kernel scope link src 10.0.2.15 metric 100 
192.168.2.0/26 dev eth1 proto kernel scope link src 192.168.2.2 metric 101 
-----------------------------------------------------
net.ipv4.conf.all.forwarding = 0
-----------------------------------------------------
```
### Конец решения
### Выполненo
