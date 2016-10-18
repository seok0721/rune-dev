#!/bin/bash
if [ -z `grep -r controller /etc/hosts` ]; then echo 127.0.0.1 controller >> /etc/hosts; fi
if [ -z `pidof mysqld` ]; then service mysql start; fi
source /etc/admin-openrc
echo "CREATE DATABASE glance" | mysql
echo "GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' IDENTIFIED BY '$GLANCE_DBPASS'" | mysql
echo "GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' IDENTIFIED BY '$GLANCE_DBPASS'" | mysql
openstack user create --domain default --password-prompt glance
openstack role add --project service --user glance admin
openstack service create --name glance --description "OpenStack Image" image
openstack endpoint create --region RegionOne image public http://controller:9292
openstack endpoint create --region RegionOne image internal http://controller:9292
openstack endpoint create --region RegionOne image admin http://controller:9292

# glance api
sed -i -- 's/^\(sqlite_db.*\)/#\1/g' /etc/glance/glance-api.conf
sed -i -- 's/^\(backend.*\)/#\1/g' /etc/glance/glance-api.conf
sed -i -- "s/^#connection =.*/connection = mysql+pymysql:\/\/glance:$GLANCE_DBPASS@controller\/glance/g" /etc/glance/glance-api.conf
sed -i -- "s/^#auth_uri =.*/auth_uri = http:\/\/controller:5000\nauth_url = http:\/\/controller:35357/g" /etc/glance/glance-api.conf
sed -i -- "s/^#memcached_servers =.*/memcached_servers = controller:11211/g" /etc/glance/glance-api.conf

###################

[keystone_authtoken]
...

auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = glance
password = GLANCE_PASS

[paste_deploy]
...
flavor = keystone

[glance_store]
...
stores = file,http
default_store = file
filesystem_store_datadir = /var/lib/glance/images/

# glance registey
[database]
...
connection = mysql+pymysql://glance:GLANCE_DBPASS@controller/glance

[keystone_authtoken]
...
auth_uri = http://controller:5000
auth_url = http://controller:35357
memcached_servers = controller:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = glance
password = GLANCE_PASS

[paste_deploy]
...
flavor = keystone

############

# service glance-registry restart
# service glance-api restart

glance-manage db_sync

wget http://download.cirros-cloud.net/0.3.4/cirros-0.3.4-x86_64-disk.img
openstack image create "cirros" \
  --file cirros-0.3.4-x86_64-disk.img \
    --disk-format qcow2 --container-format bare \
      --public
      openstack image list
