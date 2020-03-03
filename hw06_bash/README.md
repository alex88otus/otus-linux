## Урок №6: **BASH**
### Свой скрипт **loginspector**)
#### 0. Компоненты
```bash
install_loginspector.sh
loginspector
├── etc
│   ├── sysconfig
│   │   └── loginspector
│   └── systemd
│       └── system
│           ├── loginspector.service
│           └── loginspector.timer
├── opt
│   ├── loginspector.d
│   └── loginspector.sh
└── var
    └── log
        └── access-4560-644067.log
pass
```
Всё это автоматом копируется на *vm* в директорию `/vagrant`
#### 1. Описание компонентов
- [install_loginspector.sh](install_loginspector.sh) - установщик. К сожалению сервис работает только после запуска этого скрипта на VM под пользователем *vagrant*, при подключении уствновщика в Vagrantfile **mailx** выдает неизвестную ошибку.

Установка **mailx**, копирование файлов  в `/`, установка прав на рабочую директорию `/opt/loginspector.d`
```bash
sudo yum install -y mailx
sudo cp -fr /vagrant/loginspector/* /
sudo chown -R vagrant /opt/loginspector.d /opt/loginspector.sh
sudo chmod -R u=rwx,go-rwx /opt/loginspector.d/ /opt/loginspector.sh
```
Включение автозапуска сервиса
```bash
sudo systemctl daemon-reload
sudo systemctl enable loginspector.timer
```
Дополнительные настройки для работы **mailx** с smtp-сервером Google
```bash
mkdir ~/.certs
certutil -f /vagrant/pass -N -d ~/.certs
echo -n | openssl s_client -connect smtp.gmail.com:465 | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > ~/.certs/gmail.crt
certutil -A -n "Google Internet Authority" -t "C,," -d ~/.certs -i ~/.certs/gmail.crt
```
- [etc/sysconfig/loginspector](loginspector/etc/sysconfig/loginspector) - конфигурационный файл

Содржит путь к обрабатываемому логу и mail-адреса для отправки репорта (можно вписать множество адресов через пробел)
```bash
LOG=/var/log/access-4560-644067.log
MAIL="someone@gmail.com"
```
- [etc/systemd/system/loginspector.service](loginspector/etc/systemd/system/loginspector.service) - unit-файл sistemd сервиса

Содержит путь к конфигурационному файлу, путь к скрипту, указывает какие переменные передать скрипту из конфигурационного файла, также указывает под каким пользователем запускать скрипт
```bash
[Unit]
Description=My loginspector service
After=network.target
[Service]
Type=oneshot
User=vagrant
EnvironmentFile=/etc/sysconfig/loginspector
ExecStart=/opt/loginspector.sh $LOG ${MAIL}
```
- [etc/systemd/system/loginspector.timer](loginspector/etc/systemd/system/loginspector.timer) - unit-файл sistemd таймера

Автозапуск при старте системы и далее каждые 30 мин
```bash
[Unit]
Description=Run loginspector script every 30 min
Requires=loginspector.service
[Timer]
OnUnitActiveSec=30min
AccuracySec=1us
Unit=loginspector.service
[Install]
WantedBy=multi-user.target
```
- [opt/loginspector.sh](loginspector/opt/loginspector.sh) - основной Bash script файл
- [var/log/access-4560-644067.log](loginspector/var/log/access-4560-644067.log) - файл лога для обработки
- [pass](pass) - файл с паролем для утилиты `certutil`, нужен только при установке
#### 2. Описание работы скрипта [loginspector.sh](loginspector/opt/loginspector.sh)
Прием переменных из конфигурационного файла
```bash
logfile=$1
mailadd=$2
```
Определение дополнительных переменных
```bash
workpath=/opt/loginspector.d
pidfile=$workpath/pidfile
lasttime=$workpath/lasttime
date=$(date +%d/%m/%Y/%H/%M/%S)
```
Реализация "защиты от мультизапуска"
```bash
if [[ -f $pidfile ]]; then
    PID=$(cat $pidfile)
    echo "Existing pidfile: $PID"
    echo "Sleep"
    sleep 60
    if [[ -f $pidfile ]] && [[ -n $(ps -p "$PID" | grep -q "$PID") ]] && [[ -n $(ps -p "$PID" | grep -q "$(basename "$0")") ]] ; then
        kill -9 "$PID"
        echo "The old process is killed"
        rm $pidfile
        sync
    elif [[ -f $pidfile ]]; then
        rm $pidfile
        sync
    else
        echo "The old process is finished"
    fi
fi
echo $$ >$pidfile
echo "New pidfile: $(cat $pidfile)"
```
Форматирование исследуемого лога в удобоваримый формат с помощью утилит sed и awk, нужно для удобства дальнейшей обработки и операции сравнения времени. (Работоспособно только для месяца в предоставленном логе, писать для всех месяцев не вижу смысла... возможно данная реализация неоптимальна)
```bash
tempdata=$(sed -r 's/""/"empty"/;s/- - \[//;s/] "([A-Z]+ )?/ /;s/( HTTP\/1\.[01])?" / /' "$logfile" | awk '{ print $1,$2,$3,$4,$5 }' | sed 's/\///;s/\///;;s/://;s/://;s/://;s/Aug/08/')
```
Реализация функции "результаты только со времени последнего запуска скрипта", отсеивание подходящих результатов, сохранение времени последней записи лога в файл
```bash
ltime=$(cat $lasttime)
if [[ ! -f $lasttime ]] || [[ $ltime != [0-9]* ]]; then
    echo "$tempdata" | head -n1 | awk '{ print $2 }' >$lasttime
    sync
    ltime=$(cat $lasttime)
fi
workdata=$(echo "$tempdata" | awk '{if ($2>='${ltime}') print $0 }')
echo "$workdata" | tail -n1 | awk '{print $2}' >$lasttime
```
Формирование текста сообщения для отправки
```bash
tempmail=$(
    echo "Report was generated at $date";
    echo ""
    echo "Last log record in last check was at $(sed -r 's/^([0-9]{2})([0-9]{2})([0-9]{4})([0-9]{2})([0-9]{2})/\1\/\2\/\3\/\4\/\5\//' $lasttime)"
    echo ""
    echo "TOP 15 IPs with max amount of access times"
    echo "$workdata" | awk '{ ipcount[$1]++ } END { for (i in ipcount) { printf "%s %d\n", i, ipcount[i] } }' | sort -k2nr | head -n15 | awk '{printf "%2s. %s   \t%2s times\n", NR, $1, $2}'
    echo ""
    echo "TOP 10 addresses with max amount of access times"
    echo "$workdata" | awk '{ addrcount[$4]++ } END { for (i in addrcount) { printf "%s %d\n", i, addrcount[i] } }' | sort -k2nr | head -n10 | awk '{printf "%2s. %-52s\t%3s times\n", NR, $1, $2}'
    echo ""
    echo "Return codes list"
    echo "$workdata" | awk '{ codecount[$5]++ } END { for (i in codecount) { printf "%s - %3d times\n", i, codecount[i] } }' | sort -k3nr
    echo ""
    echo "List of all errors"
    echo "$workdata" | awk '{ if ($5>=400) { printf "%s %s\t%s %s\n", $5,$1,$2,$4 } }' | awk '{ printf "%2s. %s\n", NR, $0 }'
)
```
Отправка репорта с помощью **mailx**. Настройки для работы с smtp-сервером Google
```bash
echo "$tempmail" | mailx -v -s "REPORT $date" -S smtp-use-starttls -S ssl-verify=ignore -S smtp-auth=login -S smtp=smtp://smtp.gmail.com:587 -S from="user@gmail.com(John Doe)" -S smtp-auth-user=user@gmail.com -S smtp-auth-password=?????? -S ssl-verify=ignore -S nss-config-dir=~/.certs "$mailadd"
```
Естественно удаление pidfile
```bash
rm $pidfile
sync
echo "EVERYTHING IS DONE!!!!!"
```
#### 3. Результат выполнения
[REPORT 01_03_2020_13_36_40.eml](REPORT_01_03_2020_13_36_40.eml) - пример письма отправленного в первый раз
[REPORT_01_03_2020_14_06_52.eml](REPORT_01_03_2020_14_06_52.eml) - второй и последующие разы
### Конец решения
### Выполненo
