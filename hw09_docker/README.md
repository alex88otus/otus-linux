## Урок №9: **Docker**
### Решение
#### Создать кастомные образы nginx и php, объедините их в docker-compose.
[docker-compose.yml](docker-compose.yml)
```yaml
version: "3"

services:
  nginx:
    build: ./nginx
    image: alex88otus/nginx:0.1
    volumes:
      - ./cfg/etc/nginx/conf.d/default.conf:/etc/nginx/conf.d/default.conf:z
      - ./cfg/var/www/php:/var/www/php:z
    ports:
      - "8080:80"
    networks:
      - network001
    depends_on:
      - php
  php:
    build: ./php
    image: alex88otus/php:0.1
    volumes:
      - ./cfg/etc/php7/php-fpm.conf:/etc/php7/php-fpm.conf:z
      - ./cfg/etc/php7/php-fpm.d:/etc/php7/php-fpm.d:z
      - ./cfg/var/www/php:/var/www/php:z
    networks:
      - network001
networks:
  network001:
    driver: bridge
```
[Dockerfile](nginx/Dockerfile) для **nginx**
```docker
from alpine:latest

RUN apk add --no-cache nginx \
    && mkdir /run/nginx \
    && chmod 666 /run/nginx \
    && touch /run/nginx/nginx.pid \
    && chmod 666 /run/nginx/nginx.pid
RUN ln -sf /dev/stdout /var/log/nginx/access.log \
  && ln -sf /dev/stdout /var/log/nginx/error.log

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```
[Dockerfile](php/Dockerfile) для **php**
```docker
from alpine:latest

RUN apk add --no-cache php-fpm

EXPOSE 9000
CMD ["php-fpm7", "-F", "-R"]
```
#### После запуска **nginx** показывает `phpinfo()`.
![123](https://i.imgur.com/pnfqw1o.png)
#### Ссылки на репозиторий
https://hub.docker.com/repository/docker/alex88otus/nginx

https://hub.docker.com/repository/docker/alex88otus/php
#### Ответ на вопрос: Можно ли в контейнере собрать ядро?
Ответ: если мы можем в контейнер установить все небходимые утилиты и их зависимости, то и ядро сможем собрать

### Конец решения
### Выполненo задание со "звездочкой"
