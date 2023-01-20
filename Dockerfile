FROM ubuntu:latest
MAINTAINER Richard Brown

ARG MY_CN
WORKDIR /var/www

# Update the repository sources list
RUN apt-get update

# Install and run apache
RUN apt-get install -y apache2 && apt-get clean

# send logs to stdout get webcore code. generate crt
RUN git clone https://github.com/ady624/webCoRE \
    && ln -s webCoRE/dashboard webcore \
    && mkdir -p /etc/apache2/ssl \
    && openssl req -new -newkey rsa:2048 -days 9999 -nodes -x509 -subj "/C=US/ST=Oregon/L=Portland/O=Dis/CN=$MY_CN" -keyout /etc/apache2/ssl/$MY_CN.key  -out /etc/apache2/ssl/$MY_CN.crt
# removed -addext "subjectAltName = DNS:first.domain-name.com"
# add apache conf
COPY webcore-apache.conf /etc/apache2/sites-enabled/000-default.conf
ENV APACHE_LOG_DIR /var/log/apache2
EXPOSE 443

# By default, simply start apache.
CMD /usr/sbin/apache2ctl -D FOREGROUND
