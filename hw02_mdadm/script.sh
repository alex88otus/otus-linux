mkdir -p ~root/.ssh
cp ~vagrant/.ssh/auth* ~root/.ssh
yum install -y mdadm smartmontools hdparm gdisk
mdadm --zero-superblock --force /dev/sd[a-f]
mdadm --create --verbose /dev/md0 -l 10 -n 6 /dev/sd[a-f]
sleep 10
cat /proc/mdstat
mdadm -D /dev/md0
mkdir /etc/mdadm/
echo "DEVICE partitions" > /etc/mdadm/mdadm.conf
mdadm --detail --scan --verbose | awk '/ARRAY/ {print}' >> /etc/mdadm/mdadm.conf
mdadm /dev/md0 --fail /dev/sde
cat /proc/mdstat
mdadm /dev/md0 --remove /dev/sde
mdadm /dev/md0 --add /dev/sde
cat /proc/mdstat
mdadm -D /dev/md0
sleep 10
parted -s /dev/md0 mklabel gpt
parted /dev/md0 mkpart primary ext4 0% 20%
parted /dev/md0 mkpart primary ext4 20% 40%
parted /dev/md0 mkpart primary ext4 40% 60%
parted /dev/md0 mkpart primary ext4 60% 80%
parted /dev/md0 mkpart primary ext4 80% 100%
for i in $(seq 1 5); do sudo mkfs.ext4 /dev/md0p$i; done
mkdir -p /raid/part{1,2,3,4,5}
#for i in $(seq 1 5); do mount /dev/md0p$i /raid/part$i; done
for i in $(seq 1 5); do echo "/dev/md0p$i /raid/part$i ext4 defaults 0 0" >> /etc/fstab; done
mount -a
