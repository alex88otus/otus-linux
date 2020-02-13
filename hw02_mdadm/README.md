## Урок №2: **mdadm**
### Решение
#### 1. Добавление в 2х дисков в Vagrant file
```ruby
:sata5 => {
  :dfile => './sata5.vdi',
  :size => 250, # Megabytes
  :port => 5
  },
:sata6 => {
  :dfile => './sata6.vdi',
  :size => 250, # Megabytes
  :port => 6
  }
```
Отключение общих папок

`config.vm.synced_folder ".", "/vagrant", disabled: true`

Подключение файла постконфигурации
 
`config.vm.provision "shell", path: "script.sh"`

#### 2. `vagrant up`

[Vagrant file](Vagrantfile) - также собирает рэйд, монтирует, добавляет конфиг в /etc/fstab и /etc/mdadm/mdadm.conf
  
Вывод `lsblk`
```bash
otuslinux: NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
otuslinux: sda      8:0    0   40G  0 disk
otuslinux: └─sda1   8:1    0   40G  0 part /
otuslinux: sdb      8:16   0  250M  0 disk
otuslinux: sdc      8:32   0  250M  0 disk
otuslinux: sdd      8:48   0  250M  0 disk
otuslinux: sde      8:64   0  250M  0 disk
otuslinux: sdf      8:80   0  250M  0 disk
otuslinux: sdg      8:96   0  250M  0 disk
```
для демонстрации того что 6 дисков подключены корректно

#### 3. Работа файла [script.sh](script.sh)

Установка необходимых софта

`yum install -y mdadm smartmontools hdparm gdisk`

Сборка массива RAID10
```bash
mdadm --zero-superblock --force /dev/sd[b-g]
mdadm --create --verbose /dev/md0 -l 10 -n 6 /dev/sd[b-g]
```
Вывод `lsblk` и `cat /proc/mdstat`
```bash
otuslinux: NAME   MAJ:MIN RM  SIZE RO TYPE   MOUNTPOINT
otuslinux: sda      8:0    0   40G  0 disk
otuslinux: └─sda1   8:1    0   40G  0 part   /
otuslinux: sdb      8:16   0  250M  0 disk
otuslinux: └─md0    9:0    0  744M  0 raid10
otuslinux: sdc      8:32   0  250M  0 disk
otuslinux: └─md0    9:0    0  744M  0 raid10
otuslinux: sdd      8:48   0  250M  0 disk
otuslinux: └─md0    9:0    0  744M  0 raid10
otuslinux: sde      8:64   0  250M  0 disk
otuslinux: └─md0    9:0    0  744M  0 raid10
otuslinux: sdf      8:80   0  250M  0 disk
otuslinux: └─md0    9:0    0  744M  0 raid10
otuslinux: sdg      8:96   0  250M  0 disk
otuslinux: └─md0    9:0    0  744M  0 raid10
```
```bash
otuslinux: Personalities : [raid10]
otuslinux: md0 : active raid10 sdg[5] sdf[4] sde[3] sdd[2] sdc[1] sdb[0]
otuslinux:       761856 blocks super 1.2 512K chunks 2 near-copies [6/6] [UUUUUU]
otuslinux:
otuslinux: unused devices: <none>
```
Пометка диска **sde** как сбойного - `mdadm /dev/md0 --fail /dev/sde`
```bash
otuslinux: mdadm: set /dev/sde faulty in /dev/md0
```
Вывод `cat /proc/mdstat`
```bash
otuslinux: Personalities : [raid10]
otuslinux: md0 : active raid10 sdg[5] sdf[4] sde[3](F) sdd[2] sdc[1] sdb[0]
otuslinux:       761856 blocks super 1.2 512K chunks 2 near-copies [6/5] [UUU_UU]
otuslinux:
otuslinux: unused devices: <none>
```
Переподключение того же диска к массиву
```bash
mdadm /dev/md0 --remove /dev/sde
mdadm /dev/md0 --add /dev/sde
```
Вывод `mdadm -D /dev/md0`
```bash
otuslinux: Consistency Policy : resync
otuslinux:
otuslinux:     Rebuild Status : 0% complete
otuslinux:
otuslinux:               Name : otuslinux:0  (local to host otuslinux)
otuslinux:               UUID : 6571f3ee:b2e8c194:e33224e7:a71cdc66
otuslinux:             Events : 22
otuslinux:
otuslinux:     Number   Major   Minor   RaidDevice State
otuslinux:        0       8       16        0      active sync set-A   /dev/sdb
otuslinux:        1       8       32        1      active sync set-B   /dev/sdc
otuslinux:        2       8       48        2      active sync set-A   /dev/sdd
otuslinux:        6       8       64        3      spare rebuilding   /dev/sde
otuslinux:        4       8       80        4      active sync set-A   /dev/sdf
otuslinux:        5       8       96        5      active sync set-B   /dev/sdg
```
Создание конфигурационного файла **mdadm**
```bash
mkdir /etc/mdadm/
echo "DEVICE partitions" > /etc/mdadm/mdadm.conf
mdadm --detail --scan --verbose | awk '/ARRAY/ {print}' >> /etc/mdadm/mdadm.conf
```
Вывод `cat /etc/mdadm/mdadm.conf`
```bash
DEVICE partitions
ARRAY /dev/md0 level=raid10 num-devices=6 metadata=1.2 name=otuslinux:0 UUID=6571f3ee:b2e8c194:e33224e7:a71cdc66
```
Разметка рэйдмассива 5 разделами GPT, форматирование в *ext4*, добавление конфига в `/etc/fstab` и монтирование
```bash
parted -s /dev/md0 mklabel gpt
parted /dev/md0 mkpart primary ext4 0% 20%
parted /dev/md0 mkpart primary ext4 20% 40%
parted /dev/md0 mkpart primary ext4 40% 60%
parted /dev/md0 mkpart primary ext4 60% 80%
parted /dev/md0 mkpart primary ext4 80% 100%
for i in $(seq 1 5); do sudo mkfs.ext4 /dev/md0p$i; done
mkdir -p /raid/part{1,2,3,4,5}
for i in $(seq 1 5); do echo "/dev/md0p$i /raid/part$i ext4 defaults 0 0" >> /etc/fstab; done
mount -a
```
Вывод `cat /etc/fstab`
```bash
otuslinux: UUID=8ac075e3-1124-4bb6-bef7-a6811bf8b870 /                       xfs     defaults        0 0
otuslinux: /swapfile none swap defaults 0 0
otuslinux: /dev/md0p1 /raid/part1 ext4 defaults 0 0
otuslinux: /dev/md0p2 /raid/part2 ext4 defaults 0 0
otuslinux: /dev/md0p3 /raid/part3 ext4 defaults 0 0
otuslinux: /dev/md0p4 /raid/part4 ext4 defaults 0 0
otuslinux: /dev/md0p5 /raid/part5 ext4 defaults 0 0
```
Вывод `lsblk`
```bash
NAME      MAJ:MIN RM   SIZE RO TYPE   MOUNTPOINT
sda         8:0    0    40G  0 disk
└─sda1      8:1    0    40G  0 part   /
sdb         8:16   0   250M  0 disk
└─md0       9:0    0   744M  0 raid10
  ├─md0p1 259:5    0   147M  0 md     /raid/part1
  ├─md0p2 259:6    0 148.5M  0 md     /raid/part2
  ├─md0p3 259:7    0   150M  0 md     /raid/part3
  ├─md0p4 259:8    0 148.5M  0 md     /raid/part4
  └─md0p5 259:9    0   147M  0 md     /raid/part5
sdc         8:32   0   250M  0 disk
└─md0       9:0    0   744M  0 raid10
  ├─md0p1 259:5    0   147M  0 md     /raid/part1
  ├─md0p2 259:6    0 148.5M  0 md     /raid/part2
  ├─md0p3 259:7    0   150M  0 md     /raid/part3
  ├─md0p4 259:8    0 148.5M  0 md     /raid/part4
  └─md0p5 259:9    0   147M  0 md     /raid/part5
sdd         8:48   0   250M  0 disk
└─md0       9:0    0   744M  0 raid10
  ├─md0p1 259:5    0   147M  0 md     /raid/part1
  ├─md0p2 259:6    0 148.5M  0 md     /raid/part2
  ├─md0p3 259:7    0   150M  0 md     /raid/part3
  ├─md0p4 259:8    0 148.5M  0 md     /raid/part4
  └─md0p5 259:9    0   147M  0 md     /raid/part5
sde         8:64   0   250M  0 disk
└─md0       9:0    0   744M  0 raid10
  ├─md0p1 259:5    0   147M  0 md     /raid/part1
  ├─md0p2 259:6    0 148.5M  0 md     /raid/part2
  ├─md0p3 259:7    0   150M  0 md     /raid/part3
  ├─md0p4 259:8    0 148.5M  0 md     /raid/part4
  └─md0p5 259:9    0   147M  0 md     /raid/part5
sdf         8:80   0   250M  0 disk
└─md0       9:0    0   744M  0 raid10
  ├─md0p1 259:5    0   147M  0 md     /raid/part1
  ├─md0p2 259:6    0 148.5M  0 md     /raid/part2
  ├─md0p3 259:7    0   150M  0 md     /raid/part3
  ├─md0p4 259:8    0 148.5M  0 md     /raid/part4
  └─md0p5 259:9    0   147M  0 md     /raid/part5
sdg         8:96   0   250M  0 disk
└─md0       9:0    0   744M  0 raid10
  ├─md0p1 259:5    0   147M  0 md     /raid/part1
  ├─md0p2 259:6    0 148.5M  0 md     /raid/part2
  ├─md0p3 259:7    0   150M  0 md     /raid/part3
  ├─md0p4 259:8    0 148.5M  0 md     /raid/part4
  └─md0p5 259:9    0   147M  0 md     /raid/part5
```
### Конец решения
### Выполнены: базовое задание + "со звездочкой"
