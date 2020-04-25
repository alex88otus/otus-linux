## Урок №21: firewalld
### Решение
#### Подготовка
Добавим inetRouter2 с 2 дополнительными сетями:    
1 - сеть **routers**, адрес 192.168.0.5   
2 - сеть hostonly **local**, адрес 10.10.10.10   
С хостовой машины 10.10.10.10 пингуется.   
Также включаем firewalld командой `systemctl start firewalld.service`.   
На centralServer устанавливаем nginx, запускаем.
#### Проброс 8080 порта с inetRouter2 на 80 порт centralServer
- При помощи firewalld c маскарадингом
```bash
firewall-cmd --permanent --add-masquerade
firewall-cmd --permanent --add-forward-port=port=8080:proto=tcp:toport=80:toaddr=192.168.0.2
firewall-cmd --reload
```
- При помощи iptables и SNAT
```bash
iptables -I FORWARD -p tcp -d 192.168.0.2 --dport 80 -j ACCEPT
iptables -t nat -A PREROUTING -p tcp --dport 8080 -j DNAT --to-destination 192.168.0.2:80
iptables -t nat -A POSTROUTING -p tcp -o eth1 --dport 80 -d 192.168.0.2 -j SNAT --to-source 192.168.0.5
```
В логах (проверка с хостовой системы командой `curl -I 10.10.10.10:8080`)
```bash
192.168.0.5 - - [21/Apr/2020:12:42:17 +0000] "HEAD / HTTP/1.1" 200 0 "-" "curl/7.69.1" "-"
```
- При помощи iptables и без маскарадинга какого-либо (в вагрант это)
```bash
iptables -I FORWARD -p tcp -d 192.168.0.2 --dport 80 -j ACCEPT
iptables -t nat -A PREROUTING -p tcp --dport 8080 -j DNAT --to-destination 192.168.0.2:80
```
На centralServer необходимо добавить маршрут
```bash
ip route add 10.10.10.0/24 via 192.168.0.5 dev eth1
```
В логах (проверка с хостовой системы командой `curl -I 10.10.10.10:8080`)
```bash
10.10.10.1 - - [21/Apr/2020:12:51:57 +0000] "HEAD / HTTP/1.1" 200 0 "-" "curl/7.69.1" "-"
```
#### Knocking port на inetRouter
Правила iptables [iptables.rules](iptables.rules) добавляем на inetRouter
```bash
iptables-restore < /vagrant/iptables.rules
service iptables save
```
Также включаем ssh-аутентификацию по паролю, задаем пароль для пользователя vagrant
```bash
sed -i '66s/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
service sshd restart 
echo "Otus2019" | sudo passwd --stdin vagrant
```
Проверяем подключение с centralRouter, предварительно установив nmap, запуском скрипта подключения [connect.sh](connect.sh) командой `/vagrant/./connect.sh 192.168.255.1 6666 7777 8888`

Все вышеизложенные настройки в Vagrantfile.
### Конец решения
### Выполненo