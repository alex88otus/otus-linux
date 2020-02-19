# Intro

This is sample dracut module to resize root LVM partition on reboot

# Installation and usage

* install files
* uncomment and adjust `lvm_resize` in `/etc/dracut.conf.d/lvm-resize-root.conf`
* run `dracut -f` to enable module
* reboot host
* ensure root volume resized
* comment out `lvm_resize` in `/etc/dracut.conf.d/lvm-resize-root.conf`
* run `dracut -f` to disable module
