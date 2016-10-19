FROM ubuntu:16.04
RUN apt-get update

# Mandatory packages
RUN apt-get -y install openssl

# Generate resources
COPY 02-generate-admin-openrc.sh /usr/local/bin
RUN /usr/local/bin/02-generate-admin-openrc.sh

# Setup node address
COPY 03-set-node-address.sh /usr/local/bin
RUN /usr/local/bin/03-set-node-address.sh

# Install time server
RUN apt-get -y install chrony

# Setup time server
COPY 04-set-chrony-server.sh /usr/local/bin
RUN /usr/local/bin/04-set-chrony-server.sh

# Install openstack client
RUN apt-get -y install python-openstackclient

# Install database
RUN apt-get -y install mariadb-server python-pymysql

# Setup database
RUN sed -i -- 's/utf8mb4/utf8/g' /etc/mysql/mariadb.conf.d/*
RUN service mysql restart

# Install NoSQL server
RUN apt-get -y install mongodb-server mongodb-clients python-pymongo

# Setup NoSQL server
RUN sed -i -- 's/127.0.0.1/0.0.0.0/g' /etc/mongodb.conf
RUN echo 'smallfiles = true' >> /etc/mongodb.conf
RUN service mongodb restart

# Install message queue
RUN apt-get -y install rabbitmq-server

# Setup message queue
COPY 05-init-rabbitmq-server.sh /usr/local/bin
RUN /usr/local/bin/05-init-rabbitmq-server.sh
RUN service rabbitmq-server restart

# Install cache server
RUN apt-get -y install memcached python-memcache

# Install keystone
RUN apt-get -y install keystone apache2 libapache2-mod-wsgi

# Setup keystone
COPY etc/apache2/sites-available/wsgi-keystone.conf /etc/apache2/sites-available
COPY 06-init-keystone.sh /usr/local/bin
RUN /usr/local/bin/06-init-keystone.sh

# Install glance
RUN apt-get -y install glance

# Setup glance
COPY 07-init-glance.sh /usr/local/bin
RUN /usr/local/bin/07-init-glance.sh

# Install nova (except schedule)
RUN apt-get -y install nova-api nova-conductor nova-consoleauth nova-novncproxy nova-scheduler
COPY 08-init-nova.sh /usr/local/bin
RUN /usr/local/bin/08-init-nova.sh

##############
COPY 09-init-nova-compute.sh /usr/local/bin
RUN /usr/local/bin/09-init-nova-compute.sh
#RUN apt-get --force-yes -y install nova-compute

# For debugging
COPY 99-awake-server.sh /usr/local/bin
RUN apt-get -y install vim
