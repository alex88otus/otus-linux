## Урок №34: dynamic web
### Решение
#### Запустить 3 разных CMS и спроксировать через NGINX
Стенд описан в [docker-compose.yml](docker-compose.yml), `docker-compose up` через некоторое время поднимает все 3 CMS на следующих адресах:
- localhost:8080 - WordPress (PHP)
- localhost:8081 - Plone (Python)
- localhost:8082 - Ghost (JS)

В комплекте также:   
[nginx.conf](nginx.conf) - конфиг для **nginx**   

#### Скрины
![123](https://i.imgur.com/XBLA8td.png)

![123](https://i.imgur.com/JzKmrED.png)

![123](https://i.imgur.com/hHb10pp.png)
### Конец решения
### Выполненo