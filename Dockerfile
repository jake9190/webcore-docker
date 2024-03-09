FROM ubuntu:latest
MAINTAINER Richard Brown

ARG MY_CN
WORKDIR /var/www

# Update the repository sources list
RUN apt-get update \
    && apt-get -y upgrade
# Install and run apache
RUN apt-get install -y apache2 git && apt-get clean \
    && a2enmod rewrite \
    && a2enmod ssl \
    && a2enmod lbmethod_byrequests

# send logs to stdout get webcore code. generate crt
RUN git clone https://github.com/ady624/webCoRE
RUN ln -s webCoRE/dashboard webcore
RUN mkdir -p /etc/apache2/ssl
RUN openssl req -new -newkey rsa:2048 -days 9999 -nodes -x509 -subj "/C=US/ST=Oregon/L=Portland/O=Dis/CN=$MY_CN" -keyout /etc/apache2/ssl/$MY_CN.key  -out /etc/apache2/ssl/$MY_CN.crt
# removed -addext "subjectAltName = DNS:first.domain-name.com"
# add apache conf
COPY webcore-apache.conf /etc/apache2/sites-enabled/000-default.conf
VOLUME /var/log/apache2
EXPOSE 443

# By default, simply start apache.
CMD /usr/sbin/apache2ctl -D FOREGROUND
