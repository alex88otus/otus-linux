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
