## Урок №4: booting
### Решение
#### 0. Создаем VM
```bash
vagrant init centos/7
```
Вносим изменения в [Vagrantfile](Vagrantfile) дабы отобразить экран VM. Версия бокса 1804 даст нам систему уже установленную на **LVM**.
```bash
  config.vm.box_version = "1804.02"
  config.vm.provider "virtualbox" do |vb|
    # Display the VirtualBox GUI when booting the machine
    vb.gui = true
  end
```
#### 1. Получение доступа к системе без пароля
- Способ 1: `init=/bin/sh`

Строчка добавляется в параметры загрузки (куда попадаем из меню выбора ОС нажатием клавиши *е*) в конце строки начинающейся с `linux16`. Обязательно удаляем параметр `console=ttyS0,115200n8` иначе получаем *Kernel panic*. Параметры  `rhgb` и `quiet` также удаляем чтобы лицезреть процесс загрузки
```bash
	linux16 /vmlinuz-3.10.0-862.2.3.el7.x86_64 root=/dev/mapper/VolGroup00-LogVol00 ro no_timer_check console=tty0 net.ifnames=0 biosdevname=0 elevator=noop crashkernel=auto rd.lvm.lv=VolGroup00/LogVol00 rd.lvm.lv=VolGroup00/LogVol01 init=/bin/sh
```
*Ctrl-X* для загрузки, попадаем CL
```bash
sh-4.2# whoami
root
```
Вывод `mount | grep LogVol00` для просмотра параметром монтирования
```bash
/dev/mapper/VolGroup00-LogVol00 on / type xfs (ro,relatime,attr2,inode64,noquota)
```
**/** замонтирован в режиме *Read-Only*, перемонтируем в режиме *Read-Write* командой `mount -o remount,rw /`

Вывод `mount | grep LogVol00`
```bash
/dev/mapper/VolGroup00-LogVol00 on / type xfs (rw,relatime,attr2,inode64,noquota)
```
- Способ 2: `rd.break`

Идентичен первому способу, но в конце строки начинающейся с `linux16` добавляется `rd.break`
```bash
	linux16 /vmlinuz-3.10.0-862.2.3.el7.x86_64 root=/dev/mapper/VolGroup00-LogVol00 ro no_timer_check console=tty0 net.ifnames=0 biosdevname=0 elevator=noop crashkernel=auto rd.lvm.lv=VolGroup00/LogVol00 rd.lvm.lv=VolGroup00/LogVol01 rd.break
```
*Ctrl-X* для загрузки, попадаем CL
```bash
switch_root:/# whoami
sh: whoami: command not found
```
Вывод `mount | grep LogVol00` для просмотра параметром монтирования
```bash
/dev/mapper/VolGroup00-LogVol00 on /sysroot type xfs (ro,relatime,attr2,inode64,noquota)
```
Корневой раздел замонтирован в режиме *Read-Only* в директорию `/sysroot`, перемонтируем *на запись* командой `mount -o remount,rw /sysroot`

Вывод `mount | grep LogVol00`
```bash
/dev/mapper/VolGroup00-LogVol00 on /sysroot type xfs (rw,relatime,attr2,inode64,noquota)
```
ФС замонтирована *на запись*. Попробем поменять пароль администратора
```bash
switch_root:/# chroot /sysroot
sh-4.2# passwd root
Changing password for user root.
New password:
Retype new password:
passwd: all authentication tokens updated successfully.
sh-4.2# touch /.autorelabel
sh-4.2# exit
switch_root:/# exit
```
После чего система перезагрузится и можно будет логиниться с новым паролем
- Способ 3: `rw init=/sysroot/bin/sh`

Данный способ также идентичен первому, в нем с помощью параметра `rw` корневая ФС монтируется сразу *на запись*, его можно использовать и в предыдуших примерах.
```bash
	linux16 /vmlinuz-3.10.0-862.2.3.el7.x86_64 root=/dev/mapper/VolGroup00-LogVol00 rw init=/sysroot/bin/sh no_timer_check console=tty0 net.ifnames=0 biosdevname=0 elevator=noop crashkernel=auto rd.lvm.lv=VolGroup00/LogVol00 rd.lvm.lv=VolGroup00/LogVol01
```
*Ctrl-X* для загрузки, попадаем CL
```bash
:/# whoami
sh: whoami: command not found
```
Вывод `mount | grep LogVol00`
```bash
/dev/mapper/VolGroup00-LogVol00 on /sysroot type xfs (rw,relatime,attr2,inode64,noquota)
```
#### 2. Переименование VG с установленной системой
Немного информации
```bash
[root@localhost vagrant]# lsblk
NAME                    MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                       8:0    0   40G  0 disk 
|-sda1                    8:1    0    1M  0 part 
|-sda2                    8:2    0    1G  0 part /boot
`-sda3                    8:3    0   39G  0 part 
  |-VolGroup00-LogVol00 253:0    0 37.5G  0 lvm  /
  `-VolGroup00-LogVol01 253:1    0  1.5G  0 lvm  [SWAP]
```
Переименуем VG
```bash
[root@localhost vagrant]# vgrename VolGroup00 OtusRoot
  Volume group "VolGroup00" successfully renamed to "OtusRoot"
```
Заменим имя VG во всех необходимых конфигурационных файлах
```bash
sed -i 's/VolGroup00/OtusRoot/g' /etc/fstab /etc/default/grub /boot/grub2/grub.cfg
```
Пересоздадим initrd image
```bash
mkinitrd -f -v /boot/initramfs-$(uname -r).img $(uname -r)
```
Перезагрузимся и выведем `lsblk`
```bash
NAME                  MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                     8:0    0   40G  0 disk 
|-sda1                  8:1    0    1M  0 part 
|-sda2                  8:2    0    1G  0 part /boot
`-sda3                  8:3    0   39G  0 part 
  |-OtusRoot-LogVol00 253:0    0 37.5G  0 lvm  /
  `-OtusRoot-LogVol01 253:1    0  1.5G  0 lvm  [SWAP]
```
Система корректно загрузилась после переименования VG
#### 3. Добавление модуля в **initrd**
В рабочем каталоге с VM уже есть файлы тестового модуля, включим общие папки в **Vagrantfile**
```ruby
  config.vm.synced_folder ".", "/vagrant"#, disabled: true
```
Скопируем файлы
```bash
cp -r /vagrant/test-module/* /
```
Проверим
```bash
[vagrant@localhost ~]$ ll /usr/lib/dracut/modules.d/01test/
total 8
-rw-r--r--. 1 root root 126 Feb 20 17:03 module-setup.sh
-rw-r--r--. 1 root root 332 Feb 20 17:03 test.sh
```
Внесем изменения в `/etc/default/grub` для отображения процесса загрузки
```bash
sed -i 's/ rhgb quiet//g' /etc/default/grub
grub2-mkconfig -o /boot/grub2/grub.cfg
```
Пресобираем образ *initrd* командой `dracut -f -v`, проверяем наличие тестового модуля
```bash
[root@localhost vagrant]# lsinitrd -m /boot/initramfs-$(uname -r).img | grep test
test
```
Пингвин на месте
### Конец решения
### Выполненo базовое задание
