FROM busybox:latest

ADD index.html /var/www/

EXPOSE 8000

CMD busybox httpd -f -p 0.0.0.0:8000 -h /var/www/
