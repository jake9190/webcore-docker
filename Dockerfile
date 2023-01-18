FROM ubuntu:latest
MAINTAINER Richard Brown

ARG MY_CN
WORKDIR /var/www

# Update and upgrade
# install apache and mods
RUN apt-get update \
    && apt-get -y upgrade \
    && apt-get -y install apache2 git \
    && a2enmod rewrite \
    && a2enmod ssl 

# send logs to stdout get webcore code. generate crt
RUN ln -sf /dev/stdout /var/log/apache2/access.log \
    && ln -sf /dev/stdout /var/log/apache2/error.log \
    && git clone https://github.com/ady624/webCoRE \
#    && cd webCoRE \
#    && git checkout hubitat-patches \
#    && cd ../ \
    && ln -s webCoRE/dashboard webcore \
    && mkdir -p /etc/apache2/ssl \
    && openssl req -new -newkey rsa:2048 -days 9999 -nodes -x509 -subj "/C=US/ST=Oregon/L=Portland/O=Dis/CN=$MY_CN" -keyout /etc/apache2/ssl/$MY_CN.key  -out /etc/apache2/ssl/$MY_CN.crt"
# removed -addext "subjectAltName = DNS:first.domain-name.com
# add apache conf
COPY webcore-apache.conf /etc/apache2/sites-enabled/000-default.conf

EXPOSE 443

# By default, simply start apache.
CMD /usr/sbin/apache2ctl -D FOREGROUND
