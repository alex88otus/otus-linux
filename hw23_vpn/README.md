## Урок №23: vpn
### Решение
#### TUN/TAP режимы OpenVPN
Настраиваем по методичке.
Копируем сгенерированный ключ на клиент
```bash
scp /etc/openvpn/static.key vagrant@192.168.10.20:~
```
На клиенте
```bash
[root@client openvpn]# mv /home/vagrant/static.key /etc/openvpn/
[root@client openvpn]# restorecon -v static.key 
restorecon reset /etc/openvpn/static.key context unconfined_u:object_r:user_home_t:s0->unconfined_u:object_r:openvpn_etc_t:s0
```
Стартуем ovpn c обоих концов, тестируем протоколом tcp по 100 секунд.

Режим tap
```bash
[root@client openvpn]# iperf3 -c 10.10.10.1 -t 100 -i 5 -V
- - - - - - - - - - - - - - - - - - - - - - - - -
Test Complete. Summary Results:
[ ID] Interval           Transfer     Bandwidth       Retr
[  4]   0.00-100.00 sec  2.14 GBytes   184 Mbits/sec  1385             sender
[  4]   0.00-100.00 sec  2.14 GBytes   184 Mbits/sec                  receiver
CPU Utilization: local/sender 0.4% (0.1%u/0.3%s), remote/receiver 9.7% (1.5%u/8.2%s)
```
Меняем режим, рестартуем сервис (режим tun)
```bash
[root@client openvpn]# iperf3 -c 10.10.10.1 -t 100 -i 5 -V
- - - - - - - - - - - - - - - - - - - - - - - - -
Test Complete. Summary Results:
[ ID] Interval           Transfer     Bandwidth       Retr
[  4]   0.00-100.00 sec  2.24 GBytes   193 Mbits/sec  1440             sender
[  4]   0.00-100.00 sec  2.24 GBytes   192 Mbits/sec                  receiver
CPU Utilization: local/sender 0.5% (0.1%u/0.4%s), remote/receiver 2.9% (0.4%u/2.5%s)
```
Вывод: для передачи ip-траффика выгодней использовать tun-интерфейс, он будет иметь большую пропускную способность и меньше использовать CPU.
#### RAS на базе OpenVPN
Инициализируем PKI
```bash
[root@server vagrant]# cd /etc/openvpn/
[root@server openvpn]# /usr/share/easy-rsa/3/easyrsa init-pki
- - - - - - - - - - - - - - - - - - - - - - - - -
init-pki complete; you may now create a CA or requests.
Your newly created PKI dir is: /etc/openvpn/pki
```
Генерируем необходимые ключи и сертификаты для сервера
```bash
[root@server openvpn]# echo 'rasvpn' | /usr/share/easy-rsa/3/easyrsa build-ca nopass
- - - - - - - - - - - - - - - - - - - - - - - - -
Your new CA certificate file for publishing is at:
/etc/openvpn/pki/ca.crt

[root@server openvpn]# echo 'rasvpn' | /usr/share/easy-rsa/3/easyrsa gen-req server nopass
- - - - - - - - - - - - - - - - - - - - - - - - -
Keypair and certificate request completed. Your files are:
req: /etc/openvpn/pki/reqs/server.req
key: /etc/openvpn/pki/private/server.key

[root@server openvpn]# echo 'yes' | /usr/share/easy-rsa/3/easyrsa sign-req server server
- - - - - - - - - - - - - - - - - - - - - - - - -
Certificate created at: /etc/openvpn/pki/issued/server.crt

[root@server openvpn]# /usr/share/easy-rsa/3/easyrsa gen-dh
- - - - - - - - - - - - - - - - - - - - - - - - -
DH parameters of size 2048 created at /etc/openvpn/pki/dh.pem

[root@server openvpn]# openvpn --genkey --secret ta.key
```
Генерируем сертификаты для клиента
```bash
[root@server openvpn]# echo 'client' | /usr/share/easy-rsa/3/easyrsa gen-req client nopass
- - - - - - - - - - - - - - - - - - - - - - - - -
Keypair and certificate request completed. Your files are:
req: /etc/openvpn/pki/reqs/client.req
key: /etc/openvpn/pki/private/client.key

[root@server openvpn]# echo 'yes' | /usr/share/easy-rsa/3/easyrsa sign-req client client
Certificate created at: /etc/openvpn/pki/issued/client.crt
```
Создаем server.conf папке `/etc/openvpn` со следующим содержимым
```bash
port 1194
proto udp4
dev tun
ca /etc/openvpn/pki/ca.crt
cert /etc/openvpn/pki/issued/server.crt
key /etc/openvpn/pki/private/server.key
dh /etc/openvpn/pki/dh.pem
server 10.10.10.0 255.255.255.0
;route 192.168.10.0 255.255.255.0
;push "route 192.168.10.0 255.255.255.0"
ifconfig-pool-persist ipp.txt
;client-to-client
client-config-dir /etc/openvpn/client
keepalive 10 120
compress lz4-v2
push "compress lz4-v2"
persist-key
persist-tun
status /var/log/openvpn-status.log
log /var/log/openvpn.log
verb 3
```
Для клиента создаем client.conf с сертификатами внутри
```bash
dev tun
proto udp4
remote 192.168.10.10 1194
client
resolv-retry infinite
persist-key
persist-tun
status /var/log/openvpn-status.log
log /var/log/openvpn.log
verb 3
<ca>
-----BEGIN CERTIFICATE-----
-----END CERTIFICATE-----
</ca>
<cert>
-----BEGIN CERTIFICATE-----
-----END CERTIFICATE-----
</cert>
<key>
-----BEGIN PRIVATE KEY-----
-----END PRIVATE KEY-----
</key>
```
Стартуем сервер `systemctl start openvpn@server.service`, запустим клиент `sudo openvpn  --config ~/client.conf`, проверим
```bash
ping -c 4 10.10.10.1
PING 10.10.10.1 (10.10.10.1) 56(84) bytes of data.
64 bytes from 10.10.10.1: icmp_seq=1 ttl=64 time=0.422 ms
64 bytes from 10.10.10.1: icmp_seq=2 ttl=64 time=0.962 ms
64 bytes from 10.10.10.1: icmp_seq=3 ttl=64 time=1.05 ms
64 bytes from 10.10.10.1: icmp_seq=4 ttl=64 time=1.12 ms

--- 10.10.10.1 ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3008ms
rtt min/avg/max/mdev = 0.422/0.886/1.115/0.273 ms
```
Проверим маршруты на клиенте и сервере. На клиенте:
```bash
10.10.10.1 via 10.10.10.5 dev tun0 
10.10.10.5 dev tun0 proto kernel scope link src 10.10.10.6 
```
На сервере:
```bash
10.10.10.0/24 via 10.10.10.2 dev tun0 
10.10.10.2 dev tun0 proto kernel scope link src 10.10.10.1 
```
#### OpenConnect сервер
Устанавливаем `yum install -y ocserv` на сервере, на клиенте `yum install -y openconnect`.

Из коробки ocserv работает с PAM (нужен пароль для локального пользователя). В конфигурационный файл достаточно добавить:   
`compression = true` для сжатия  
`ipv4-network = 10.10.10.0/24` пул адресов для туннельных интерфейсов   
`route = 10.10.10.0/255.255.255.0` соответствующий маршрут для клиентов   
`banner = "Welcome"` - MOTD    
Запускаем `systemctl start ocserv.service`, подключаемся с хоста (также подключимся с виртуалки client)
```bash
sudo openconnect 192.168.10.10
POST https://192.168.10.10/
Connected to 192.168.10.10:443
SSL negotiation with 192.168.10.10
Server certificate verify failed: signer not found

Certificate from VPN server "192.168.10.10" failed verification.
Reason: signer not found
To trust this server in future, perhaps add this to your command line:
    --servercert pin-sha256:CFFPZ+ipFS56UzkRNp8O0QXfbcuBSQaDgrzlMXJ4Ad8=
Enter 'yes' to accept, 'no' to abort; anything else to view: yes
Connected to HTTPS on 192.168.10.10
XML POST enabled
Please enter your username.
Username:root
POST https://192.168.10.10/auth
Please enter your password.
Password:
POST https://192.168.10.10/auth
Got CONNECT response: HTTP/1.1 200 CONNECTED
CSTP connected. DPD 90, Keepalive 32400
Connected as 10.10.10.170, using SSL + LZ4, with DTLS + LZ4 in progress
Established DTLS connection (using GnuTLS). Ciphersuite (DTLS1.2)-(PSK)-(AES-128-GCM).
DTLS connection compression using LZ4.
Connect Banner:
| Welcome
```
На клиенте добавляется маршрут `10.10.10.0/24 dev tun0 scope link`, пинг до сервера работает
```bash
ping 10.10.10.1 -c 2
PING 10.10.10.1 (10.10.10.1) 56(84) bytes of data.
64 bytes from 10.10.10.1: icmp_seq=1 ttl=64 time=0.469 ms
64 bytes from 10.10.10.1: icmp_seq=2 ttl=64 time=0.965 ms

--- 10.10.10.1 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1007ms
rtt min/avg/max/mdev = 0.469/0.717/0.965/0.248 ms
```
На сервере для каждого клиента создаются интерфейсы, клиенты изолированы
```bash
27: vpns0: <POINTOPOINT,UP,LOWER_UP> mtu 1434 qdisc pfifo_fast state UNKNOWN group default qlen 500
    link/none 
    inet 10.10.10.1 peer 10.10.10.170/32 scope global vpns0
       valid_lft forever preferred_lft forever
    inet6 fe80::66da:b414:405:cbd5/64 scope link flags 800 
       valid_lft forever preferred_lft forever
28: vpns1: <POINTOPOINT,UP,LOWER_UP> mtu 1434 qdisc pfifo_fast state UNKNOWN group default qlen 500
    link/none 
    inet 10.10.10.1 peer 10.10.10.48/32 scope global vpns1
       valid_lft forever preferred_lft forever
    inet6 fe80::29d9:75d2:c5fa:ef38/64 scope link flags 800 
       valid_lft forever preferred_lft forever
```
Маршруты на сервере
```bash
10.10.10.48 dev vpns1 proto kernel scope link src 10.10.10.1 
10.10.10.170 dev vpns0 proto kernel scope link src 10.10.10.1 
```
Протестируем скорость
```bash
[root@client vagrant]# iperf3 -c 10.10.10.1 -t 100 -i 5 -V
Test Complete. Summary Results:
[ ID] Interval           Transfer     Bandwidth       Retr
[  4]   0.00-100.00 sec  4.53 GBytes   389 Mbits/sec  20952             sender
[  4]   0.00-100.00 sec  4.52 GBytes   389 Mbits/sec                  receiver
CPU Utilization: local/sender 0.7% (0.1%u/0.7%s), remote/receiver 3.7% (0.4%u/3.3%s)
```
### Конец решения
### Выполненo