#!/bin/bash

# Install elrepo
#yum install -y http://www.elrepo.org/elrepo-release-7.0-3.el7.elrepo.noarch.rpm
# Install new kernel
#yum --enablerepo elrepo-kernel install kernel-ml -y
# Remove older kernels (Only for demo! Not Production!)
#rm -f /boot/*3.10*
# Update GRUB
#grub2-mkconfig -o /boot/grub2/grub.cfg
#grub2-set-default 0

#установка необходимых утилит
yum groupinstall -y "Development Tools"
yum install -y wget openssl-devel elfutils-libelf-devel bc
#Скачиваем исходники нового ядра
wget https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.5.3.tar.xz
tar -xvf linux-5.5.3.tar.xz
cd linux-5.5.3
cp /boot/config-$(uname -r) .config
#Редактирование конфига для устранения ошибки в процессе компиляции
sed -ri '/CONFIG_SYSTEM_TRUSTED_KEYS/s/=.+/=""/g' .config
sh -c 'yes "" | make oldconfig'
make -j 12
sudo make -j 12 modules_install
sudo make -j 12 install
sudo grub2-mkconfig -o /boot/grub2/grub.cfg
sudo grub2-set-default 0
#Очистка
cd ..
rm -rf linux-5.5.3
echo "Grub update done."
# Reboot VM
shutdown -r now
