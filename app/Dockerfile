FROM busybox:latest

ADD index.html /var/www/

EXPOSE 80

CMD busybox httpd -f -p 0.0.0.0:80 -h /var/www/
