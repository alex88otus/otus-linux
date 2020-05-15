## Урок №26: nginx
### Простая защита от ДДОС средствами nginx
#### Изменения
В [Dockerfile](Dockerfile) добавил слой `COPY index.html /opt/index.html` - для наглядности.  
В nginx.conf добавил следующее
```bash
server {

    server_name localhost;
    root /opt;
    
    location / {
        if ($cookie_id != "Qwerty") {
            rewrite ^/(.*)$ /get_cookie__$1 redirect;
        }
    }

    location ~ /get_cookie__.* {
        add_header Set-Cookie "id=Qwerty;Max-Age=15";
        rewrite ^.*__(.*)$ /$1 redirect;
    }

}
```
В `location /` по сути попадает любой запрос (кроме того который удовлетворяет регулярке `/get_cookie__.*`) и сразу проверяется значение `cookie_id` и если оно отлично от заданной, то деректива `rewrite` меняет `request_uri` и возвращает редирект. При этом в новом `request_uri` сохраняется старый `request_uri` что дает нам возможность после получения `Cookie` перенаправиться в изначальный `request_uri`. Для `Cookie` задано время жизни в 15 секунд.
#### Проверка утилитой curl
Запускаем командой `docker run -p 80:80 -t alex88otus/nginx_ddos:latest` и проверяем
```bash
curl http://localhost/otus.txt

<html>
<head><title>302 Found</title></head>
<body>
<center><h1>302 Found</h1></center>
<hr><center>nginx/1.17.10</center>
</body>
</html>
```
```bash
curl -c cookie -b cookie http://localhost/otus.txt -i -L

HTTP/1.1 302 Moved Temporarily
Server: nginx/1.17.10
Date: Fri, 15 May 2020 22:40:17 GMT
Content-Type: text/html
Content-Length: 146
Location: http://localhost/get_cookie__otus.txt
Connection: keep-alive

HTTP/1.1 302 Moved Temporarily
Server: nginx/1.17.10
Date: Fri, 15 May 2020 22:40:17 GMT
Content-Type: text/html
Content-Length: 146
Location: http://localhost/otus.txt
Connection: keep-alive
Set-Cookie: id=Qwerty;Max-Age=15

HTTP/1.1 200 OK
Server: nginx/1.17.10
Date: Fri, 15 May 2020 22:40:17 GMT
Content-Type: text/plain
Content-Length: 22
Last-Modified: Thu, 14 May 2020 22:24:00 GMT
Connection: keep-alive
ETag: "5ebdc500-16"
Accept-Ranges: bytes

alex88otus/nginx_ddos
```
+иллюстрация на тему "как это выглядит в хроме"

![123](https://i.imgur.com/AFynleS.png)
### Конец решения
### Выполненo

