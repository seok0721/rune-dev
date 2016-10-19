#!/bin/bash

# Initialize environment
if [ -z `grep -r controller /etc/hosts` ]; then echo 127.0.0.1 controller >> /etc/hosts; fi
if [ -z `pidof mysqld` ]; then service mysql start; fi
if [ -z `pidof apache2` ]; then service apache2 start; fi
source /etc/admin-openrc
source /root/root-openrc

# Setup configuration
echo "DROP database if exists glance" | mysql
echo "CREATE DATABASE glance" | mysql
echo "GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' IDENTIFIED BY '$GLANCE_DBPASS'" | mysql
echo "GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' IDENTIFIED BY '$GLANCE_DBPASS'" | mysql

# Initialize openstack
openstack user create --domain default --password $GLANCE_PASS glance
openstack role add --project service --user glance admin
openstack service create --name glance --description "OpenStack Image" image
openstack endpoint create --region RegionOne image public http://controller:9292
openstack endpoint create --region RegionOne image internal http://controller:9292
openstack endpoint create --region RegionOne image admin http://controller:9292

# Setup glance-api.conf

## [database]
sed -i -- 's/^\(sqlite_db.*\)/#\1/g' /etc/glance/glance-api.conf
sed -i -- "s/^#connection =.*/connection = mysql+pymysql:\/\/glance:$GLANCE_DBPASS@controller\/glance/g" /etc/glance/glance-api.conf
sed -i -- "s/^#auth_uri =.*/auth_uri = http:\/\/controller:5000\nauth_url = http:\/\/controller:35357/g" /etc/glance/glance-api.conf
sed -i -- "s/^#memcached_servers =.*/memcached_servers = controller:11211/g" /etc/glance/glance-api.conf

## [keystone_authtoken]
sed -i -- "s/^#auth_type =.*/auth_type = password\nproject_domain_name = default\nuser_domain_name = default\nproject_name = service\nusername = glance\npassword = $GLANCE_PASS/g" /etc/glance/glance-api.conf

## [paste_deploy]
sed -i -- "s/^#flavor =.*/flavor = keystone/g" /etc/glance/glance-api.conf

## [glance store]
sed -i -- "s/^#stores =.*/stores = file,http/g" /etc/glance/glance-api.conf
sed -i -- "s/^#default_store =.*/default_store = file/g" /etc/glance/glance-api.conf
sed -i -- "s/^#filesystem_store_datadir =.*/filesystem_store_datadir = \/var\/lib\/glance\/images\//g" /etc/glance/glance-api.conf

# Setup glance-registry.conf

## [database]
sed -i -- 's/^\(sqlite_db.*\)/#\1/g' /etc/glance/glance-registry.conf
sed -i -- "s/^#connection =.*/connection = mysql+pymysql:\/\/glance:$GLANCE_DBPASS@controller\/glance/g" /etc/glance/glance-registry.conf

## [keystone_authtoken]
sed -i -- "s/^#auth_uri =.*/auth_uri = http:\/\/controller:5000\nauth_url = http:\/\/controller:35357/g" /etc/glance/glance-registry.conf
sed -i -- "s/^#memcached_servers =.*/memcached_servers = controller:11211/g" /etc/glance/glance-registry.conf
sed -i -- "s/^#auth_type =.*/auth_type = password\nproject_domain_name = default\nuser_domain_name = default\nproject_name = service\nusername = glance\npassword = $GLANCE_PASS/g" /etc/glance/glance-registry.conf

## [paste_deploy]
sed -i -- "s/^#flavor =.*/flavor = keystone/g" /etc/glance/glance-registry.conf

# Synchoronize glance
glance-manage db_sync

# Restart glance
service glance-registry restart
service glance-api restart

# Issue token
unset OS_TOKEN
openstack token issue

# Verity operation
cd /root
wget http://download.cirros-cloud.net/0.3.4/cirros-0.3.4-x86_64-disk.img
openstack image create "cirros" --file cirros-0.3.4-x86_64-disk.img --disk-format qcow2 --container-format bare --public
openstack image list
