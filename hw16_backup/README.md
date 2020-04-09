## Урок №16: **Borg**
### Решение
#### Бэкапирование с Borg
Стенд описан в [Vagrantfile](Vagrantfile), бэкапирование работает сразу после `vagrant up`.
#### Настройка сервера
Добавялем пользователя borg с созданием домашнего каталога `useradd -m borg`, копируем файл [authorized_keys](.ssh/authorized_keys) для возможности подключения по ssh.
`command="borg serve"` в файле говорит о том, что только эта команда доступна для запуска пользователю при подключении по ssh.

Устанавливаем cам Borg.
```bash
wget -q https://github.com/borgbackup/borg/releases/download/1.1.11/borg-linux64 -O /usr/local/bin/borg
chmod +x /usr/local/bin/borg
```
Процесс установки одинаков как для сервера так и для клиента.
#### Настройка клиента
Для полного бэкапа `/etc` нужен root-доступ, соответственно все настройки делаем для root.
Копируем ключи, настраиваем ssh
```bash
mkdir ~root/.ssh
cp /vagrant/.ssh/id_rsa ~root/.ssh
chmod 600 ~root/.ssh/id_rsa
ssh-keyscan -H 192.168.11.11 >> ~root/.ssh/known_hosts
```
Копируем наш скрипт, делаем исполняемым
```bash
cp /vagrant/borg_backup.sh /opt
chmod +x /opt/borg_backup.sh
```
В скрипте [borg_backup.sh](borg_backup.sh) команда создания архива, `BORG_PASSPHRASE=Qwerty1234` переменная с паролем для доступа к шифрованному репозиторию Borg, ключ `-C lzma,9` для максимального сжатия архива, `borg@192.168.11.11:BACKUP::client-etc_{now}` соответственно "юзер"@"адрес подключения к серверу":"имя репозитория"::"имя архива с датой и временем", `/etc` то что бэкапируем, `&>> /var/log/borg.log` для записи стандастного вывода и ошибок в лог.

Копируем cronfile [root](root) `cp /vagrant/root /var/spool/cron`.
```bash
*/10 * * * * /opt/borg_backup.sh
```
Так как каждый бэкап утилитой Borg - это дедуплицированный полный бэкап, то по условию задания запускаем скрипт каждые 10 минут.

В финале запуск инициализации Borg-репозитория
```bash
export BORG_PASSPHRASE=Qwerty1234
/usr/local/bin/./borg init -e repokey borg@192.168.11.11:BACKUP
```
Ключ `-e repokey` говорит о создании шифрованного репозитория с паролем и ключом, который будет храниться внутри репозитория.

Перечитываем конфигурацию cron командой `systemctl reload crond`
#### Результаты работы
... запуска на 2 часа
```bash
[root@client vagrant]# /usr/local/bin/borg list borg@192.168.11.11:BACKUP
Enter passphrase for key ssh://borg@192.168.11.11/./BACKUP: 
client-etc_2020-04-01T21:30:02       Wed, 2020-04-01 21:30:03 [f8cd2453294785a6280ecfac077f47671f0e9181ba1e93dbb13f672e38deb8d7]
client-etc_2020-04-01T21:40:01       Wed, 2020-04-01 21:40:02 [be3ebcd2543e442939f7e46892b3aa0e1138466ac4b294978433874ea6ffcf33]
client-etc_2020-04-01T21:50:02       Wed, 2020-04-01 21:50:03 [7dddf994c298e4275829e3070c187e2021149577fd7a1b3c53335f5b7bb7234a]
client-etc_2020-04-01T22:00:02       Wed, 2020-04-01 22:00:03 [68f5051738d013289b6402552a34ba526b381cf251937b50ba61024b3fbf194d]
client-etc_2020-04-01T22:10:01       Wed, 2020-04-01 22:10:02 [dcdfbd10d42891441de93bf3baa7e483b4bb7feb2b003b66dc9e3872a6332c4a]
client-etc_2020-04-01T22:20:02       Wed, 2020-04-01 22:20:03 [ca0f904f3995aa1aacd88c80c5095f1706074875779784633651fc11c2d1ce88]
client-etc_2020-04-01T22:30:02       Wed, 2020-04-01 22:30:03 [bf8fd84658aeec46e5f2808429f049e368b6604405d8d8801c781fbe218fe5ac]
client-etc_2020-04-01T22:40:01       Wed, 2020-04-01 22:40:02 [be330a91024a8852c96f5ec1e493941308e0c5099f1d787dd2ff7f387e50c711]
client-etc_2020-04-01T22:50:01       Wed, 2020-04-01 22:50:03 [fbbc01f52b1a8e6e14344cd2edbd2e6bf4851ae89509f6519423da4bae28c3e9]
client-etc_2020-04-01T23:00:02       Wed, 2020-04-01 23:00:03 [1baece9cff7d36ee0539c72eb7dda4a08427e49925143e4f47a5c69c84e223b9]
client-etc_2020-04-01T23:10:01       Wed, 2020-04-01 23:10:02 [2b2161f925a89a9ef3701f86ca63c80a1a341498eab0b0382c5c34dbe32ae26c]
client-etc_2020-04-01T23:20:01       Wed, 2020-04-01 23:20:02 [bcbe3a4f28fcb62a4ed0e380cabc4a1b6a7d503e3bcfe85a4db6dee180d6f9d4]
client-etc_2020-04-01T23:30:01       Wed, 2020-04-01 23:30:02 [ade4e9c57c6bc51306b620c98a624ff5d2d8256d776366ee6b43bb3e2ed36ae6]
```
```bash
------------------------------------------------------------------------------
Archive name: client-etc_2020-04-01T23:30:01
Archive fingerprint: ade4e9c57c6bc51306b620c98a624ff5d2d8256d776366ee6b43bb3e2ed36ae6
Time (start): Wed, 2020-04-01 23:30:02
Time (end):   Wed, 2020-04-01 23:30:03
Duration: 0.28 seconds
Number of files: 1690
Utilization of max. archive size: 0%
------------------------------------------------------------------------------
                       Original size      Compressed size    Deduplicated size
This archive:               27.81 MB              9.23 MB                599 B
All archives:              361.47 MB            119.94 MB              8.81 MB

                       Unique chunks         Total chunks
Chunk index:                    1290                21880
------------------------------------------------------------------------------
```
### Конец решения
### Выполненo задание со "звездочкой"