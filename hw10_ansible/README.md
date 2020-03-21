## Урок №10: **Ansible**
### Решение
#### Развертывание **nginx**
Развертывание происходит с использованием Ansible роли.
Иерархия файлов ниже, всё в этом репозитории.
```bash
.
├── ansible.cfg
├── inventories
│   └── all.yml
├── nginx.yml
├── README.md
├── roles
│   └── nginx
│       ├── defaults
│       │   └── main.yml
│       ├── handlers
│       │   └── main.yml
│       ├── tasks
│       │   ├── configure.yml
│       │   ├── install.yml
│       │   └── main.yml
│       └── templates
│           └── nginx.conf.j2
└── Vagrantfile
```
После `vagrant up` смотрим `vagrant ssh-config` и меняем порт в файле [inventories/all.yml](inventories/all.yml)

Запускаем
`ansible-playbook nginx.yml`, смотрим вывод
```bash
PLAY [NGINX | Install and configure NGINX] **************************************************************

TASK [Gathering Facts] **********************************************************************************
ok: [nginx]

TASK [nginx : NGINX | install | EPEL Repo package from standart repo] ***********************************
changed: [nginx]

TASK [nginx : NGINX | install | NGINX package from EPEL Repo] *******************************************
changed: [nginx]

TASK [nginx : NGINX | configure | Create NGINX config file from template] *******************************
changed: [nginx]

RUNNING HANDLER [nginx : restart nginx] *****************************************************************
changed: [nginx]

RUNNING HANDLER [nginx : reload nginx] ******************************************************************
changed: [nginx]

PLAY RECAP **********************************************************************************************
nginx                      : ok=6    changed=5    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
```
Логинимся на vm, проверяем состояние сервиса **nginx**
```
[root@nginx vagrant]# systemctl status nginx.service 
● nginx.service - The nginx HTTP and reverse proxy server
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; enabled; vendor preset: disabled)
   Active: active (running) since Sat 2020-03-21 21:56:53 UTC; 25min ago
  Process: 30304 ExecReload=/bin/kill -s HUP $MAINPID (code=exited, status=0/SUCCESS)
  Process: 30216 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
  Process: 30212 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)
  Process: 30211 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
 Main PID: 30218 (nginx)
   CGroup: /system.slice/nginx.service
           ├─30218 nginx: master process /usr/sbin/nginx
           └─30305 nginx: worker process

Mar 21 21:56:53 nginx systemd[1]: Starting The nginx HTTP and reverse proxy server...
Mar 21 21:56:53 nginx nginx[30212]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
Mar 21 21:56:53 nginx nginx[30212]: nginx: configuration file /etc/nginx/nginx.conf test is successful
Mar 21 21:56:53 nginx systemd[1]: Failed to read PID from file /run/nginx.pid: Invalid argument
Mar 21 21:56:53 nginx systemd[1]: Started The nginx HTTP and reverse proxy server.
Mar 21 21:56:53 nginx systemd[1]: Reloading The nginx HTTP and reverse proxy server.
Mar 21 21:56:53 nginx systemd[1]: Reloaded The nginx HTTP and reverse proxy server.
```
Конфигурационный файл
```
[root@nginx vagrant]# cat /etc/nginx/nginx.conf
# Ansible managed
events {
    worker_connections 1024;
}

http {
    server {
        listen       8080 default_server;
        server_name  default_server;
        root         /usr/share/nginx/html;

        location / {
        }
    }
}
```
И перейдем на страничку

![123](https://i.imgur.com/7O6fHxJ.png)
### Конец решения
### Выполненo задание со "звездочкой"