## Урок №17: Logging
### Решение
#### Развернуть стенд с ELK
Стенд описан в [Vagrantfile](Vagrantfile), всё работает сразу после `vagrant up`. Vagrant разворачивает стек (Filebeat -> Logstash -> Elasticsearch <- Kibana) на 4 виртуальных машинах.

Удобная команда для запуска виртуалок одновременно:
```bash
grep config.vm.define Vagrantfile | awk -F'"' '{print $2}' | xargs -P4 -I {} vagrant up {}
```
#### Установка и настройка стека
Компонены стека (Filebeat, Logstash, Elasticsearch, Kibana) устанавливаются из офф репозитория, в соответствии копируются конфигурационные файлы - [filebeat.yml](conf/filebeat.yml), [logstash.conf](conf/logstash.conf), [elasticsearch.yml](conf/elasticsearch.yml), [kibana.yml](conf/kibana.yml); после запускаются соответствующие unit-файлы, vm `web` c Filebeat перезагружается для применения всех изменений.
#### Настроить аудит следящий за изменением конфигов нжинкса
Копируем файл [nginx.rules](conf/nginx.rules) в папку `/etc/audit/rules.d`. Содержание файла:
```bash
-w /etc/nginx -p wa -k nginx-etc_watch
```
`-w /etc/nginx` - слежение за дерикторией `/etc/nginx`и за всеми вложенными файлами, `-p wa` - какие события логгируем (в данном случае это изменение файлов и изменение атрибутов файлов), `-k nginx-etc_watch` - какой ключ присваиваем событиям (для удобства поиска)
#### Все критичные логи с `web` должны собираться и локально и удаленно
Для этого копируем файл [rsyslog.conf](conf/rsyslog.conf) в папку `/etc`. Изменения в отличии от оригинального файла:
```bash
*.crit;mail.none;authpriv.none;cron.none                /var/log/messages

# The authpriv file has restricted access.
authpriv.crit                                              /var/log/secure
```
Для логов `/var/log/messages` и `/var/log/secure` записываем и храним только события критической важности.
А для того чтобы Filebeat отправлял системные логи просто включаем соответствующий модуль командой `filebeat modules enable system`.
#### Все логи с nginx должны уходить на удаленный сервер (локально только критичные)
Добавим строчку в конфиг nginx [nginx.conf](conf/nginx.conf) чтобы сохранять критичные логи в отдельный файл.
```bash
error_log  /var/log/nginx/error_crit.log crit;
```
Изменим настройку logrotate для nginx в файле [nginx](conf/nginx) соответствующим образом
```bash
/var/log/nginx/error.log
/var/log/nginx/access.log
{
        rotate 0
        missingok
        notifempty
        size 100k
        create 640 nginx adm
        sharedscripts
        postrotate
                if [ -f /var/run/nginx.pid ]; then
                        kill -USR1 `cat /var/run/nginx.pid`
                fi
        endscript
}
```
Вследствие при запуске logrotate основные файлы конфига будут затираться (при достижении определенного размера), а лог критичных событий останется нетронутым.
Для отправки всех событий nginx в удаленный инстанс скопируем измененный файл модуля nginx для Filebeat [nginx.yml](conf/nginx.yml), где мы явно указали какие логи читаем, в папку `/etc/filebeat/modules.d`.
#### Логи аудита должны также уходить на удаленную систему
Для этого просто включаем модуль для Filebeat командой `filebeat modules enable auditd`
#### Результаты
Logstash занимается обработкой логов и, в зависимости от того какие модули мы используем в Filebeat или какие логи читаем, именует индексы соответствующим образом и кладет их в Elasticseach.
```bash
[root@web vagrant]# curl http://192.168.11.10:9200/_cat/indices
yellow open nginx-access-2020.04.05  CZ3xeTBoTHmCwLTVkBBiHA 1 1   26 0 139.4kb 139.4kb
yellow open nginx-access-2020.04.07  JJrhuX6AReObJMaLatp8Mw 1 1  828 0   463kb   463kb
green  open .apm-agent-configuration d8Y59-y8SEmba8UT0T98Fg 1 0    0 0    283b    283b
yellow open system-syslog-2020.04.06 hUzbcg4eSGCgtuogNDHVcw 1 1 4379 0   1.6mb   1.6mb
yellow open system-syslog-2020.04.07 pBCJrTFzQ4SFyq7d696isw 1 1 2463 0 932.6kb 932.6kb
yellow open system-syslog-2020.04.05 ScTxe43RTc2UbthXpnk27w 1 1 1243 0 565.5kb 565.5kb
green  open .kibana_1                m7k4x7K2TIWPgCtCw_m9Lw 1 0   16 5  63.3kb  63.3kb
green  open .kibana_task_manager_1   46fuqEPjRTaCtg7N7pRP4w 1 0    2 0  41.3kb  41.3kb
yellow open auditd-log-2020.04.06    eOd6V_Z0Q_aCcJzU7guQiw 1 1 2396 0   1.3mb   1.3mb
yellow open system-auth-2020.04.05   ve2Cp9W3TsyYuXrNOGZ3Gg 1 1   76 0 175.6kb 175.6kb
yellow open nginx-error-2020.04.05   S1a9tyOpRy-Rm1_LpdTkTg 1 1   11 0 133.3kb 133.3kb
yellow open system-auth-2020.04.06   7hwEUsisT6iyLzrGXvrAdA 1 1  194 0 246.5kb 246.5kb
yellow open auditd-log-2020.04.07    Rqck9BcgTqKA_Ft06l5tVQ 1 1 1469 0 890.2kb 890.2kb
yellow open system-auth-2020.04.07   dZ_Bz0z3TtiW7zJ5gpCdQg 1 1   88 0 164.1kb 164.1kb
yellow open nginx-error-2020.04.07   84_PLy3YSMWUNS42E3Wgeg 1 1  534 0 199.2kb 199.2kb
```
### Конец решения
### Выполненo