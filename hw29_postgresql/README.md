## Урок №16: **Borg**
### Решение
#### Бэкапирование с Borg
Стенд описан в [Vagrantfile](Vagrantfile), бэкапирование работает сразу после `vagrant up`.
#### Настройка сервера `backup`
Добавялем пользователя borg с созданием домашнего каталога `useradd -m borg`, копируем файл [authorized_keys](.ssh/authorized_keys) для возможности подключения по ssh.
`command="borg serve"` в файле говорит о том, что только эта команда доступна для запуска пользователю при подключении по ssh.

Устанавливаем cам Borg.
```bash
yum install -y epel-release
yum install -y borgbackup
```
Процесс установки одинаков как для сервера так и для клиента.
#### Настройка клиента `server`
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
В скрипте [borg_backup.sh](borg_backup.sh):
- Конструкция для защиты от мультизапуска
```bash
LOCKFILE=/tmp/lockfile
if [ -e $LOCKFILE ] && kill -0 "$(cat $LOCKFILE)"; then
    echo "already running"
    exit
fi

# Make sure the lockfile is removed when we exit and then claim it
trap 'rm -f $LOCKFILE; exit' INT TERM EXIT
echo $$ >$LOCKFILE

******

# Delete lockfile
rm -f $LOCKFILE
```
- Команда создания архива  - `borg create` где ключ `-C lzma,9` для максимального сжатия архива, `"$BACKUP_USER"@"$BACKUP_HOST":"$BACKUP_REPO"::etc_{now}` соответственно "юзер"@"адрес подключения к серверу":"имя репозитория"::"имя архива с датой и временем" (берется из соответствующих переменных), `/etc` то что бэкапируем, `2>>$LOG` для записи потока ошибок в лог.
- Команда очистки репозитория от старых архивов - `borg prune` где `--keep-within=30d` оставляет все архивы за последние 30 дней и `--keep-monthly=2` оставляет ещё по одному последнему архиву каждого из последних двух месяцев.

Копируем cronfile [root](root) `cp /vagrant/root /var/spool/cron`, запускает borg раз в час.
```bash
0 * * * * /opt/borg_backup.sh
```

В финале запуск инициализации Borg-репозитория
```bash
export BORG_PASSPHRASE=Qwerty1234
borg init -e repokey borg@192.168.11.11:BACKUP
```
Ключ `-e repokey` говорит о создании шифрованного репозитория с паролем и ключом, который будет храниться внутри репозитория.
`BORG_PASSPHRASE=Qwerty1234` переменная с паролем для доступа к шифрованному репозиторию Borg соответственно есть и в скрипте.

Перечитываем конфигурацию cron командой `systemctl reload crond`
#### Пример лог файла
```bash
------------------------------------------------------------------------------
------------------------------------------------------------------------------
2020-05-23T09:38:28+0000 BORGBACKUP INIT
------------------------------------------------------------------------------
A repository already exists at borg@192.168.11.11:BACKUP.
------------------------------------------------------------------------------
DONE
------------------------------------------------------------------------------
------------------------------------------------------------------------------
2020-05-23T10:00:01+0000 BORGBACKUP CREATE
------------------------------------------------------------------------------
Archive name: etc_2020-05-23T10:00:01
Archive fingerprint: f71a0a3331cfcf60c69272c8eda4bffbbbc979cddec057cb9a45c149afe3e822
Time (start): Sat, 2020-05-23 10:00:02
Time (end):   Sat, 2020-05-23 10:00:04
Duration: 1.33 seconds
Number of files: 1699
Utilization of max. archive size: 0%
------------------------------------------------------------------------------
                       Original size      Compressed size    Deduplicated size
This archive:               28.43 MB              9.37 MB             71.94 kB
All archives:                1.22 GB            402.81 MB              9.32 MB

                       Unique chunks         Total chunks
Chunk index:                    1384                72935
------------------------------------------------------------------------------
DONE
------------------------------------------------------------------------------
------------------------------------------------------------------------------
2020-05-23T10:00:01+0000 BORGBACKUP PRUNE
------------------------------------------------------------------------------
Keeping archive: etc_2020-05-23T10:00:01              Sat, 2020-05-23 10:00:02 [f71a0a3331cfcf60c69272c8eda4bffbbbc979cddec057cb9a45c149afe3e822]
Keeping archive: etc_2020-05-23T09:36:01              Sat, 2020-05-23 09:36:02 [72f51c5102f68eb2c431df6855db9834735bd97bba6db827ee3ab81f8694a11e]
------------------------------------------------------------------------------
DONE
```
#### Восстановление файлов
Монтируем borg-репозиторий
```bash
borg mount borg@192.168.11.11:BACKUP /mnt
```
Проверяем
```bash
[root@server vagrant]# ll /mnt/
total 0
drwxr-xr-x. 1 root root 0 May 23 09:36 etc_2020-05-23T09:36:01
drwxr-xr-x. 1 root root 0 May 23 10:00 etc_2020-05-23T10:00:01
drwxr-xr-x. 1 root root 0 May 23 11:00 etc_2020-05-23T11:00:02
drwxr-xr-x. 1 root root 0 May 23 12:00 etc_2020-05-23T12:00:01
[root@server vagrant]# cd /mnt/etc_2020-05-23T12\:00\:01/
[root@server etc_2020-05-23T12:00:01]# ll
total 0
drwxr-xr-x. 1 root root 0 May 23 09:38 etc
```
Восстанавливаем данные
```bash
yes | cp -rf etc /
```
Работает.
### Конец решения
### Выполненo задание со "звездочкой"