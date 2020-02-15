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
```
Установка Packer
```bash
sudo -s
curl https://releases.hashicorp.com/packer/1.5.1/packer_1.5.1_linux_amd64.zip | sudo gzip -d > /usr/local/bin/packer && sudo chmod +x /usr/local/bin/packer
```
#### 2. Редактирование конфигурационных файлов для Packer
- [centos.json](packer/centos.json) - конфигурационный файл для Packer
```bash
{
  "variables": {
    "artifact_description": "CentOS 7.7 with kernel 5.5.4",
    "artifact_version": "7.7.1908",
    "image_name": "centos-7-5"
  },
```
Достаточный объем диска для сборки ядра из исходников
```bash
      "disk_size": "25000",
```
Для ускорения сборки
```bash
      "vboxmanage": [
        [  "modifyvm",  "{{.Name}}",  "--memory",  "2048" ],
        [  "modifyvm",  "{{.Name}}",  "--cpus",  "12" ]
```
Смотрим, где скрипты для постконфигурации
```bash
          "scripts" :
            [
              "scripts/stage-1-kernel-update.sh",
              "scripts/stage-2-clean.sh"
            ]
```
- [stage-1-kernel-update.sh](packer/scripts/stage-1-kernel-update.sh)

Установка необходимых утилит
```bash
yum groupinstall -y "Development Tools"
yum install -y wget openssl-devel elfutils-libelf-devel bc
```
Скачивание и распаковка исходников нового ядра
```bash
wget https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.5.4.tar.xz
tar -xvf linux-5.5.4.tar.xz
cd linux-5.5.4
```
Подготовка сонфигурационного файла ос
```bash
cp /boot/config-$(uname -r) .config
sed -ri '/CONFIG_SYSTEM_TRUSTED_KEYS/s/=.+/=""/g' .config
sh -c 'yes "" | make oldconfig'
```
Компиляция и установка
```bash
make -j 12
sudo make -j 12 modules_install
sudo make -j 12 install
```
Настройка загрузчика
```bash
sudo grub2-mkconfig -o /boot/grub2/grub.cfg
sudo grub2-set-default 0
```
Очистка
```bash
cd ..
rm -rf linux-5.5.4 linux-5.5.4.tar.xz
```
- Создаем Vagrant box в автоматическом режиме командой `packer build centos.json`

Результатом будет являться файл **centos-7.7.1908-kernel-5-x86_64-Minimal.box**
#### 4. Тестирование созданного образа в Vagrant
Сразу зальем его в Vagrant cloud, опублекуем
```bash
vagrant cloud publish --release alex88otus/centos-7-5 1.0 virtualbox centos-7.7.1908-kernel-5-x86_64-Minimal.box
```
Редактируем имеющийся [Vagrantfile](Vargantfile) для запуска нового образа и его проверки

Изменяем **box_name**
```bash
              # VM box
              :box_name => "alex88otus/centos-7-5",
```
Запускаем `vagrant up`, логинимся `vagrant ssh`, смотрим версию ядра
```bash
[vagrant@kernel-update ~]$ uname -r
5.5.4
```

