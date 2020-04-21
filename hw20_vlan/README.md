## Урок №20: team and vlan
### Решение
#### Конфигурирование
Поднимаем виртукалки поочередно командой `vagrant up` чтобы не сбился форвардинг портов. 
VM описаны в [Vagrantfile](Vagrantfile), настраиваиваемые интерфейсы не сконфигурированы.
Настройка производится c с помощью конфигурационных файлов для `network-scripts`, находятся в папке [templates](templates).
В комплекте: inventory-файл [all.yml](inventory/all.yml), playbook [net.yml](net.yml).
Конфигурирование запускается командой `ansible-playbook net.yml`
#### Результаты
Teaming на inetRouter и centralRouter работает корректно, поочередное отключение интерфейсов проверено.
```bash
[root@inetRouter vagrant]# teamdctl team0 state
setup:
  runner: activebackup
ports:
  eth1
    link watches:
      link summary: up
      instance[link_watch_0]:
        name: ethtool
        link: up
        down count: 0
  eth2
    link watches:
      link summary: up
      instance[link_watch_0]:
        name: ethtool
        link: up
        down count: 0
runner:
  active port: eth1

[root@centralRouter vagrant]# teamdctl team0 state
setup:
  runner: activebackup
ports:
  eth1
    link watches:
      link summary: up
      instance[link_watch_0]:
        name: ethtool
        link: up
        down count: 0
  eth2
    link watches:
      link summary: up
      instance[link_watch_0]:
        name: ethtool
        link: up
        down count: 0
runner:
  active port: eth1
```
VLAN-изоляция также работает. 
Запускаем следующую команду на testClient1
```
arping -b -I eth1.100(1) 10.10.10.1
```
Слушаем на centralRouter на интерфейсе eth3.100
```
[root@centralRouter vagrant]# tcpdump -e -i eth3.100
tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
listening on eth3.100, link-type EN10MB (Ethernet), capture size 262144 bytes
11:09:35.628744 08:00:27:0a:12:4e (oui Unknown) > Broadcast, ethertype ARP (0x0806), length 60: Request who-has 10.10.10.1 (Broadcast) tell 10.10.10.254, length 46
11:09:36.629296 08:00:27:0a:12:4e (oui Unknown) > Broadcast, ethertype ARP (0x0806), length 60: Request who-has 10.10.10.1 (Broadcast) tell 10.10.10.254, length 46
```
Слышно. 
При запуске же на eth3.101 - ничего.
Если запустим на eth3, то увидим уже vlan по которому идет arp-бродкаст.
```
[root@centralRouter vagrant]# tcpdump -e -i eth3
tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
listening on eth3, link-type EN10MB (Ethernet), capture size 262144 bytes
11:09:42.634300 08:00:27:0a:12:4e (oui Unknown) > Broadcast, ethertype 802.1Q (0x8100), length 64: vlan 100, p 0, ethertype ARP, Request who-has 10.10.10.1 (Broadcast) tell 10.10.10.254, length 46
11:09:43.634980 08:00:27:0a:12:4e (oui Unknown) > Broadcast, ethertype 802.1Q (0x8100), length 64: vlan 100, p 0, ethertype ARP, Request who-has 10.10.10.1 (Broadcast) tell 10.10.10.254, length 46
```
### Конец решения
### Выполненo