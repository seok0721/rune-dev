#!/bin/bash

# Initialize environment
if [ -z `grep -r controller /etc/hosts` ]; then echo "127.0.0.1 controller" >> /etc/hosts; fi
if [ -z `pidof mysqld` ]; then service mysql start; fi
source /etc/admin-openrc

# Setup configuration
echo "manual" > /etc/init/keystone.override
sed -i -- "s/^#admin_token.*$/admin_token = $ADMIN_PASS/g" /etc/keystone/keystone.conf
sed -i -- "s/^connection =.*$/connection = mysql+pymysql:\/\/keystone:$KEYSTONE_DBPASS@controller\/keystone/g" /etc/keystone/keystone.conf
sed -i -- 's/^#provider.*$/provider = fernet/g' /etc/keystone/keystone.conf
echo "ServerName controller" >> /etc/apache2/apache2.conf
ln -s /etc/apache2/sites-available/wsgi-keystone.conf /etc/apache2/sites-enabled
# Initialize database
echo "DROP database if exists keystone" | mysql
echo "CREATE DATABASE keystone" | mysql
echo "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY '$KEYSTONE_DBPASS'" | mysql
echo "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY '$KEYSTONE_DBPASS'" | mysql
keystone-manage db_sync
keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
service apache2 restart

# Generate root openstack
echo "export OS_TOKEN=$ADMIN_PASS" > /root/root-openrc
echo "export OS_URL=http://controller:35357/v3" >> /root/root-openrc
echo "export OS_IDENTITY_API_VERSION=3" >> /root/root-openrc
source /root/root-openrc

# Initialize openstack
openstack service create --name keystone --description "OpenStack Identity" identity
openstack endpoint create --region RegionOne identity public http://controller:5000/v3
openstack endpoint create --region RegionOne identity internal http://controller:5000/v3
openstack endpoint create --region RegionOne identity admin http://controller:35357/v3
openstack domain create --description "Default Domain" default
openstack project create --domain default --description "Admin Project" admin
openstack user create --domain default --password $ADMIN_PASS admin
openstack role create admin
openstack role add --project admin --user admin admin
openstack project create --domain default --description "Service Project" service
openstack project create --domain default --description "Demo Project" demo
openstack user create --domain default --password $ADMIN_PASS demo
openstack role create user
openstack role add --project demo --user demo user

# Append admin-openrc
echo "
export OS_PROJECT_DOMAIN_NAME=default
export OS_USER_DOMAIN_NAME=default
export OS_PROJECT_NAME=admin
export OS_USERNAME=admin
export OS_PASSWORD=$ADMIN_PASS
export OS_AUTH_URL=http://controller:35357/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2" >> /etc/admin-openrc

# Generate demo-openrc
echo "export OS_PROJECT_DOMAIN_NAME=default
export OS_USER_DOMAIN_NAME=default
export OS_PROJECT_NAME=demo
export OS_USERNAME=demo
export OS_PASSWORD=$ADMIN_PASS
export OS_AUTH_URL=http://controller:5000/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2" > /etc/demo-openrc
