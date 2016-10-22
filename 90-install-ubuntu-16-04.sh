#!/bin/bash
apt-get update

# Mandatory packages
apt-get -y install openssl git vim

cd /tmp
git clone http://github.com/seok0721/rune-dev
cd /tmp/rune-dev

# Generate resources
cp 02-generate-admin-openrc.sh /usr/local/bin
/usr/local/bin/02-generate-admin-openrc.sh

# Setup node address
cp 03-set-node-address.sh /usr/local/bin
/usr/local/bin/03-set-node-address.sh

# Install time server
apt-get -y install chrony

# Setup time server
cp 04-set-chrony-server.sh /usr/local/bin
/usr/local/bin/04-set-chrony-server.sh

# Install openstack client
apt-get -y install python-openstackclient

# Install database
apt-get -y install mariadb-server python-pymysql

# Setup database
sed -i -- 's/utf8mb4/utf8/g' /etc/mysql/mariadb.conf.d/*
service mysql restart

# Install NoSQL server
apt-get -y install mongodb-server mongodb-clients python-pymongo

# Setup NoSQL server
sed -i -- 's/127.0.0.1/0.0.0.0/g' /etc/mongodb.conf
echo 'smallfiles = true' >> /etc/mongodb.conf
service mongodb restart

# Install message queue
apt-get -y install rabbitmq-server

# Setup message queue
cp 05-init-rabbitmq-server.sh /usr/local/bin
/usr/local/bin/05-init-rabbitmq-server.sh
service rabbitmq-server restart

# Install cache server
apt-get -y install memcached python-memcache

# Install keystone
apt-get -y install keystone apache2 libapache2-mod-wsgi

# Setup keystone
cp etc/apache2/sites-available/wsgi-keystone.conf /etc/apache2/sites-available
cp 06-init-keystone.sh /usr/local/bin
/usr/local/bin/06-init-keystone.sh

# Install glance
apt-get -y install glance

# Setup glance
cp 07-init-glance.sh /usr/local/bin
/usr/local/bin/07-init-glance.sh

# Install nova (except schedule)
apt-get -y install nova-api nova-conductor nova-consoleauth nova-novncproxy nova-scheduler
cp 08-init-nova.sh /usr/local/bin
/usr/local/bin/08-init-nova.sh

# Install nova compute
apt-get -y install nova-compute
cp 09-init-nova-compute.sh /usr/local/bin
/usr/local/bin/09-init-nova-compute.sh

# Install neutron
apt-get -y install neutron-server neutron-plugin-ml2 neutron-linuxbridge-agent neutron-dhcp-agent neutron-metadata-agent
cp 10-init-neutron.sh /usr/local/bin
/usr/local/bin/10-init-neutron.sh

# For debugging
#cp 99-awake-server.sh /usr/local/bin
