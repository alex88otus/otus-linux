## Урок №24: ospf
### FRRouting
#### Подготовка
[Vagrantfile](Vagrantfile) c 3 виртуалками R1, R2 и R3, попарно соединены сетями intnet + для каждой отдельная сеть hostonly для провижининга.
| int | R1 | R2 | R3 |
| - | - | - | - |
| eth2 | 10.10.12.1/30 (net12) | 10.10.23.1/30 (net23) | 10.10.31.1/30 (net31) |
| eth3 | 10.10.31.2/30 (net31) | 10.10.12.2/30 (net12) | 10.10.23.2/30 (net23) |
Устанавливаем frr
```bash
wget https://ci1.netdef.org/artifact/LIBYANG-YANGRELEASE/shared/build-10/CentOS-7-x86_64-Packages/libyang-0.16.111-0.x86_64.rpm
wget https://github.com/FRRouting/frr/releases/download/frr-7.2/frr-7.2-01.el7.centos.x86_64.rpm
yum install -y libyang-0.16.111-0.x86_64.rpm
yum install -y frr-7.2-01.el7.centos.x86_64.rpm
```
Настройка frr осуществляется Ansible. В комплекте инвентори-файл [inventory/all.yml](inventory/all.yml) c необходимыми переменными, [папка](templates) с конфигами ospfd.conf в формате j2.
Playbook [frr_1.yml](frr_1.yml) для настройки асимметричного роутинга.

В нем копирование конфига
```yaml
  - name: cp ospf configs to hosts
    template:
      src: ospfd.conf.j2
      dest: /etc/frr/ospfd.conf
      owner: frr
      group: frr
      mode: 0644
```
включение нужного нам демона ospfd
```yaml
  - name: make sure line 'ospfd=yes' is set in /etc/frr/daemons
    ini_file:
      path: /etc/frr/daemons
      state: present
      no_extra_spaces: yes
      section: null
      option: ospfd
      value: 'yes'
      owner: frr
      group: frr
      mode: 0750
      backup: no
```
рестарт службы frr
```yaml
  - name: (re)start frr
    systemd:
      name: frr
      state: restarted
      enabled: yes
```
включение форвардинга ipv4 пакетов + отключение Reverse Path Filtering
```yaml
  - name: Enable IPv4 forwarding
    sysctl:
      name: net.ipv4.conf.all.forwarding
      value: '1'
      sysctl_set: yes
  - name: Enable IPv4 rp_filter
    sysctl:
      name: net.ipv4.conf.{{ item }}.rp_filter
      value: '0'
      sysctl_set: yes
    with_items:
      - all
      - eth2
      - eth3
```
Playbook [frr_2.yml](frr_2.yml) для настройки симметричного роутинга c дорогим линком.
#### Изображаем асимметричный роутинг
Запускаем провижининг командой `ansible-playbook frr_1.yml`.
В данном случае для интерфейса eth3 каждого роутера прописывается на настройка `ip ospf cost 250` которая делает интерфейс более дорогим.
Проверяем роутинг с хостов следующим способом
```bash
for q in 12.1 12.2 23.1 23.2 31.1 31.2; do tracepath -n "10.10.$q"; done
```
Асимметричный роутинг сработал по одному разу для каждого хоста
```bash
[vagrant@R1 ~]
 1?: [LOCALHOST]                                         pmtu 1500
 1:  10.10.12.2                                            0.357ms 
 1:  10.10.12.2                                            0.350ms 
 2:  10.10.23.2                                            0.596ms reached
     Resume: pmtu 1500 hops 2 back 1 

[vagrant@R2 ~]
 1?: [LOCALHOST]                                         pmtu 1500
 1:  10.10.23.2                                            0.333ms 
 1:  10.10.23.2                                            0.327ms 
 2:  10.10.31.2                                            0.501ms reached
     Resume: pmtu 1500 hops 2 back 1 

[vagrant@R3 ~]
 1?: [LOCALHOST]                                         pmtu 1500
 1:  10.10.31.2                                            0.399ms 
 1:  10.10.31.2                                            0.301ms 
 2:  10.10.12.2                                            0.472ms reached
     Resume: pmtu 1500 hops 2 back 1 
```
#### Изображаем симметричный роутинг с дорогим линком
Запускаем провижининг командой `ansible-playbook frr_2.yml`.
В данном случаем делаем дорогим только линк между R1 и R3 и вклучаем rp_filter (не обязательно).
Наблюдаем следующее на R1 и R3
```bash
[root@R1 vagrant]# for q in 12.1 12.2 23.1 23.2 31.1 31.2; do tracepath -n "10.10.$q"; done
 1?: [LOCALHOST]                                         pmtu 1500
 1:  10.10.12.2                                            1.009ms reached
 1:  10.10.12.2                                            0.809ms reached
     Resume: pmtu 1500 hops 1 back 1 
 1?: [LOCALHOST]                                         pmtu 1500
 1:  10.10.23.1                                            1.035ms reached
 1:  10.10.23.1                                            1.228ms reached
     Resume: pmtu 1500 hops 1 back 1 
 1?: [LOCALHOST]                                         pmtu 1500
 1:  10.10.12.2                                            0.820ms 
 1:  10.10.12.2                                            0.913ms 
 2:  10.10.23.2                                            1.704ms reached
     Resume: pmtu 1500 hops 2 back 2 
 1?: [LOCALHOST]                                         pmtu 1500
 1:  10.10.31.1                                            0.327ms reached
 1:  10.10.31.1                                            0.308ms reached
     Resume: pmtu 1500 hops 1 back 1 

[root@R3 vagrant]# for q in 12.1 12.2 23.1 23.2 31.1 31.2; do tracepath -n "10.10.$q"; done
 1?: [LOCALHOST]                                         pmtu 1500
 1:  10.10.23.1                                            1.317ms 
 1:  10.10.23.1                                            1.037ms 
 2:  10.10.12.1                                            1.824ms reached
     Resume: pmtu 1500 hops 2 back 2 
 1?: [LOCALHOST]                                         pmtu 1500
 1:  10.10.12.2                                            0.724ms reached
 1:  10.10.12.2                                            0.814ms reached
     Resume: pmtu 1500 hops 1 back 1 
 1?: [LOCALHOST]                                         pmtu 1500
 1:  10.10.23.1                                            0.762ms reached
 1:  10.10.23.1                                            0.731ms reached
     Resume: pmtu 1500 hops 1 back 1 
 1?: [LOCALHOST]                                         pmtu 1500
 1:  10.10.31.2                                            0.386ms reached
 1:  10.10.31.2                                            0.299ms reached
     Resume: pmtu 1500 hops 1 back 1 
```
В результате сколько хопов туда столько и обратно.
### Конец решения
### Выполненo