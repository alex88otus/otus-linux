## Урок №3: **LVM**
### Решение
#### 0. Редактируем  [Vagrantfile](Vagrantfile)
```ruby
vb.customize ["modifyvm", :id, "--memory", "1024"]
```
```ruby
yum install -y mdadm smartmontools hdparm gdisk xfsdump
```
#### 1. Уменьшение размера для **/** до 8GB
>Процесс уменьшения - это просто создание нового раздела в 8G, копирование туда данных из **/** и настройка для последующей загрузки с нового раздела

`vagrant up`, `vagrant ssh` и вывод `lsblk`
```bash
NAME                    MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                       8:0    0   40G  0 disk 
├─sda1                    8:1    0    1M  0 part 
├─sda2                    8:2    0    1G  0 part /boot
└─sda3                    8:3    0   39G  0 part 
  ├─VolGroup00-LogVol00 253:0    0 37.5G  0 lvm  /
  └─VolGroup00-LogVol01 253:1    0  1.5G  0 lvm  [SWAP]
sdb                       8:16   0   10G  0 disk 
sdc                       8:32   0    2G  0 disk 
sdd                       8:48   0    1G  0 disk 
sde                       8:64   0    1G  0 disk 
```
Добавляем дополнительный диск в имеющуюся Volume Group, создаем на ней раздел **lv_root** размером 8G, создаем файловую систему, монтируем, копируем всё с **/**
```bash
pvcreate /dev/sdb
vgextend VolGroup00 /dev/sdb
lvcreate -n lv_root -L 8G VolGroup00
mkfs.xfs /dev/VolGroup00/lv_root
mount /dev/VolGroup00/lv_root /mnt
xfsdump -J - /dev/VolGroup00/LogVol00 | xfsrestore -J - /mnt
```
Проверка
```bash
[root@lvm vagrant]# ls /mnt/
bin   dev  home  lib64  mnt  proc  run   srv  tmp  vagrant
boot  etc  lib   media  opt  root  sbin  sys  usr  var
```
Далее биндим необходимые каталоги в новую рут деректорию командой `for i in /proc/ /sys/ /dev/ /run/ /boot/; do mount --bind $i /mnt/$i; done` и вывод `mount -l` для проверки
```bash
proc on /mnt/proc type proc (rw,nosuid,nodev,noexec,relatime)
sysfs on /mnt/sys type sysfs (rw,nosuid,nodev,noexec,relatime,seclabel)
devtmpfs on /mnt/dev type devtmpfs (rw,nosuid,seclabel,size=498008k,nr_inodes=124502,mode=755)
tmpfs on /mnt/run type tmpfs (rw,nosuid,nodev,seclabel,mode=755)
/dev/sda2 on /mnt/boot type xfs (rw,relatime,seclabel,attr2,inode64,noquota)
```
Чрутимся и обновляем конфигурацию загрузчика
```bash
[root@lvm vagrant]# chroot /mnt/
[root@lvm /]# grub2-mkconfig -o /boot/grub2/grub.cfg
Generating grub configuration file ...
Found linux image: /boot/vmlinuz-3.10.0-862.2.3.el7.x86_64
Found initrd image: /boot/initramfs-3.10.0-862.2.3.el7.x86_64.img
done
```
Обновим образ initrd
```bash
cd /boot ; for i in `ls initramfs-*img`; do dracut -v $i `echo $i|sed "s/initramfs-//g; s/.img//g"` --force; done
```
Отредактируем grub.cfg для загрузки с правильного раздела
```bash
sed -i 's/VolGroup00\/LogVol00/VolGroup00\/lv_root/g' grub2/grub.cfg
```
Перезагружаемся и делаем вывод `lsblk`
```bash
NAME                    MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                       8:0    0   40G  0 disk 
├─sda1                    8:1    0    1M  0 part 
├─sda2                    8:2    0    1G  0 part /boot
└─sda3                    8:3    0   39G  0 part 
  ├─VolGroup00-LogVol01 253:1    0  1.5G  0 lvm  [SWAP]
  └─VolGroup00-LogVol00 253:2    0 37.5G  0 lvm  
sdb                       8:16   0   10G  0 disk 
└─VolGroup00-lv_root    253:0    0    8G  0 lvm  /
sdc                       8:32   0    2G  0 disk 
sdd                       8:48   0    1G  0 disk 
sde                       8:64   0    1G  0 disk 
```
Система успешно загрузилась с другого раздела. Удаляем ненужный Logical Volume. Перемещаем lv_root на /dev/sda3, удаляем /dev/sdb из VolGroup00
```bash
lvremove /dev/VolGroup00/LogVol00
pvmove /dev/sdb
vgreduce VolGroup00 /dev/sdb
```
Вывод `lsblk`
```bash
NAME                    MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                       8:0    0   40G  0 disk 
├─sda1                    8:1    0    1M  0 part 
├─sda2                    8:2    0    1G  0 part /boot
└─sda3                    8:3    0   39G  0 part 
  ├─VolGroup00-lv_root  253:0    0    8G  0 lvm  /
  └─VolGroup00-LogVol01 253:1    0  1.5G  0 lvm  [SWAP]
sdb                       8:16   0   10G  0 disk 
sdc                       8:32   0    2G  0 disk 
sdd                       8:48   0    1G  0 disk 
sde                       8:64   0    1G  0 disk 
```
#### 3. **/var** - в mirror
Добавляем 2 диска по 1G как Phisical Volumes, создаем на них Volume Group, создаем Logical Volume как зеркало
```bash
[root@lvm vagrant]# pvcreate /dev/sde /dev/sdd
  Physical volume "/dev/sde" successfully created.
  Physical volume "/dev/sdd" successfully created.
[root@lvm vagrant]# vgcreate vg_var /dev/sde /dev/sdd
  Volume group "vg_var" successfully created
[root@lvm vagrant]#  lvcreate -L 1000M -m 1 -n lv_var vg_var
  Logical volume "lv_var" created.
```
Создаем файловую систему ext4, монтируем, копируем содержимое каталога **/var**, переименовываем оригинальный каталог в **/var.old**, монтируем **lv_var** в новый каталог **/var**
```bash
mkfs.ext4 /dev/vg_var/lv_var
mount /dev/vg_var/lv_var /mnt
cp -ax /var/* /mnt/
mv /var /var.old
umount /mnt
mkdir /var
mount /dev/vg_var/lv_var /var
```
Правим  **/etc/fstab** длā автоматического монтирования
```bash
echo "`blkid | grep var: | awk '{print $2}'` /var ext4 defaults 0 0" >> /etc/fstab
```
Перезагружаемся, выводим `lsblk`
```bash
NAME                     MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                        8:0    0   40G  0 disk 
├─sda1                     8:1    0    1M  0 part 
├─sda2                     8:2    0    1G  0 part /boot
└─sda3                     8:3    0   39G  0 part 
  ├─VolGroup00-lv_root   253:0    0    8G  0 lvm  /
  └─VolGroup00-LogVol01  253:1    0  1.5G  0 lvm  [SWAP]
sdb                        8:16   0   10G  0 disk 
sdc                        8:32   0    2G  0 disk 
sdd                        8:48   0    1G  0 disk 
├─vg_var-lv_var_rmeta_1  253:4    0    4M  0 lvm  
│ └─vg_var-lv_var        253:6    0 1000M  0 lvm  /var
└─vg_var-lv_var_rimage_1 253:5    0 1000M  0 lvm  
  └─vg_var-lv_var        253:6    0 1000M  0 lvm  /var
sde                        8:64   0    1G  0 disk 
├─vg_var-lv_var_rmeta_0  253:2    0    4M  0 lvm  
│ └─vg_var-lv_var        253:6    0 1000M  0 lvm  /var
└─vg_var-lv_var_rimage_0 253:3    0 1000M  0 lvm  
  └─vg_var-lv_var        253:6    0 1000M  0 lvm  /var
```
#### 4. **/home** - сделать том для снэпшотов
- Создаем Logical Volume размером 2G на **VolGroup00**, файловую систему xfs, монтируем, копируем файлы из каталога **/home**, стираем всё в оригинальном каталоге, перемонтируем раздел на место оригинальнго каталога
```bash
lvcreate -n LogVol_Home -L 2G /dev/VolGroup00
mkfs.xfs /dev/VolGroup00/LogVol_Home
mount /dev/VolGroup00/LogVol_Home /mnt/
cp -aR /home/* /mnt/
rm -rf /home/*
umount /mnt
mount /dev/VolGroup00/LogVol_Home /home/
```
Правим  **/etc/fstab** длā автоматического монтирования
```bash
echo "`blkid | grep Home | awk '{print $2}'` /home xfs defaults 0 0" >> /etc/fstab
```
Перезагружаемся, выводим `lsblk`
```bash
NAME                       MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                          8:0    0   40G  0 disk 
├─sda1                       8:1    0    1M  0 part 
├─sda2                       8:2    0    1G  0 part /boot
└─sda3                       8:3    0   39G  0 part 
  ├─VolGroup00-lv_root     253:0    0    8G  0 lvm  /
  ├─VolGroup00-LogVol01    253:1    0  1.5G  0 lvm  [SWAP]
  └─VolGroup00-LogVol_Home 253:7    0    2G  0 lvm  /home
```
- Генерируем файлы в деректории /home, создаем том для снэпшотов
```bash
[root@lvm /]# touch /home/file{1..20}
[root@lvm /]# lvcreate -L 100MB -s -n home_snap /dev/VolGroup00/LogVol_Home
  Rounding up size to full physical extent 128.00 MiB
  Logical volume "home_snap" created.
```
Вывод `lsblk`
```bash
NAME                            MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                               8:0    0   40G  0 disk 
├─sda1                            8:1    0    1M  0 part 
├─sda2                            8:2    0    1G  0 part /boot
└─sda3                            8:3    0   39G  0 part 
  ├─VolGroup00-lv_root          253:0    0    8G  0 lvm  /
  ├─VolGroup00-LogVol01         253:1    0  1.5G  0 lvm  [SWAP]
  ├─VolGroup00-LogVol_Home-real 253:8    0    2G  0 lvm  
  │ ├─VolGroup00-LogVol_Home    253:7    0    2G  0 lvm  /home
  │ └─VolGroup00-home_snap      253:10   0    2G  0 lvm  
  └─VolGroup00-home_snap-cow    253:9    0  128M  0 lvm  
    └─VolGroup00-home_snap      253:10   0    2G  0 lvm  
```
 Потрем некоторое кол-во файлов, восстановим раздел со снэпшота
```bash
[root@lvm /]# rm -f /home/file{11..20}
[root@lvm /]# umount /home/
[root@lvm /]# lvconvert --merge /dev/VolGroup00/home_snap
  Merging of volume VolGroup00/home_snap started.
  VolGroup00/LogVol_Home: Merged: 100.00%
[root@lvm /]# mount /home/
```
Как результат файлы все на месте, снэпшот раздел исчез. Результат записан в файл [typescript](typescript).
### Конец решения
### Выполненo базовое задание
