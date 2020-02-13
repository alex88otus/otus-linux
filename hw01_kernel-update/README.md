## Урок №1: kernel update
### Решение
#### 1. Установка VirtualBox, Vagrant и Paker
Установка необходимого софта
```bash
yum -y install wget gcc make perl elfutils-libelf-devel git kernel-devel
```
Установка VirtualBox
```bash
wget -P /etc/yum.repos.d/ https://download.virtualbox.org/virtualbox/rpm/el/virtualbox.repo
yum -y install VirtualBox-6.1
```
Установка Vagrant 
```bash
yum -y install https://releases.hashicorp.com/vagrant/2.2.7/vagrant_2.2.7_x86_64.rpm
vagrant plugin install vagrant-vbguest
```
Установка Pacer
```bash
sudo -s
curl https://releases.hashicorp.com/packer/1.5.1/packer_1.5.1_linux_amd64.zip | sudo gzip -d > /usr/local/bin/packer && sudo chmod +x /usr/local/bin/packer
```

```

