FROM nginx:alpine
COPY nginx.conf /etc/nginx/nginx.conf
COPY otus.txt  /opt/otus.txt
COPY index.html  /opt/index.html
CMD ["nginx","-g","daemon off;"]
