FROM ubuntu:16.04
RUN apt-get update

# Mandatory packages
RUN apt-get -y install openssl

COPY 02-generate-admin-openrc.sh /usr/local/bin
RUN /usr/local/bin/02-generate-admin-openrc.sh

COPY 03-set-node-address.sh /usr/local/bin
RUN /usr/local/bin/03-set-node-address.sh

RUN apt-get -y install chrony
COPY 04-set-chrony-server.sh /usr/local/bin
RUN /usr/local/bin/04-set-chrony-server.sh

# Mitaka only
#RUN apt-get -y install software-properties-common

RUN apt-get -y install python-openstackclient
RUN apt-get -y install mariadb-server python-pymysql

RUN sed -i -- 's/utf8mb4/utf8/g' /etc/mysql/mariadb.conf.d/*
RUN service mysql restart

RUN apt-get -y install mongodb-server mongodb-clients python-pymongo
RUN sed -i -- 's/127.0.0.1/0.0.0.0/g' /etc/mongodb.conf
RUN echo 'smallfiles = true' >> /etc/mongodb.conf
RUN service mongodb restart

COPY 06-init-rabbitmq-server.sh /usr/local/bin
RUN /usr/local/bin/06-init-rabbitmq-server.sh

RUN apt-get -y install memcached python-memcache
RUN service memcached restart

RUN apt-get -y install keystone apache2 libapache2-mod-wsgi
COPY 05-init-keystone.sh /usr/local/bin
COPY etc/apache2/sites-available/wsgi-keystone.conf /etc/apache2/sites-available
RUN /usr/local/bin/05-init-keystone.sh

RUN apt-get -y install glance

# For debugging
RUN apt-get -y install vim
