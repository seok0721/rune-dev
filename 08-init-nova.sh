#!/bin/bash

# Initialize environment
if [ -z `grep -r controller /etc/hosts` ]; then echo 127.0.0.1 controller >> /etc/hosts; fi
if [ -z `pidof mysqld` ]; then service mysql start; fi
if [ -z `pidof apache2` ]; then service apache2 start; fi
source /etc/admin-openrc
source /root/root-openrc
unset OS_TOKEN

# Setup database
echo "drop database if exists nova_api" | mysql
echo "drop database if exists nova" | mysql
echo "CREATE DATABASE nova_api" | mysql
echo "CREATE DATABASE nova" | mysql
echo "GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'localhost' IDENTIFIED BY '$NOVA_DBPASS'" | mysql
echo "GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'%' IDENTIFIED BY '$NOVA_DBPASS'" | mysql
echo "GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'localhost' IDENTIFIED BY '$NOVA_DBPASS'" | mysql
echo "GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'%' IDENTIFIED BY '$NOVA_DBPASS'" | mysql

# Setup openstack
openstack user create --domain default --password $NOVA_PASS nova
openstack role add --project service --user nova admin
openstack service create --name nova --description "OpenStack Compute" compute
openstack endpoint create --region RegionOne compute public http://controller:8774/v2.1/%\(tenant_id\)s
openstack endpoint create --region RegionOne compute internal http://controller:8774/v2.1/%\(tenant_id\)s
openstack endpoint create --region RegionOne compute admin http://controller:8774/v2.1/%\(tenant_id\)s

# Setup configuration
echo "
auth_strategy = keystone
firewall_driver = nova.virt.firewall.NoopFirewallDriver
my_ip = 0.0.0.0
rpc_backend = rabbit
use_neutron = True

[api_database]
connection = mysql+pymysql://nova:$NOVA_DBPASS@controller/nova_api

[database]
connection = mysql+pymysql://nova:$NOVA_DBPASS@controller/nova

[oslo_messaging_rabbit]

rabbit_host = controller
rabbit_userid = openstack
rabbit_password = $RABBIT_PASS

[keystone_authtoken]
auth_uri = http://controller:5000
auth_url = http://controller:35357
memcached_servers = controller:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = nova
password = $NOVA_PASS

[vnc]
enabled = True
vncserver_listen = \$my_ip
vncserver_proxyclient_address = \$my_ip
novncproxy_base_url = http://controller:6080/vnc_auto.html

[glance]
api_servers = http://controller:9292

[oslo_concurrency]
lock_path = /var/lib/nova/tmp" >> /etc/nova/nova.conf

# Synchoronize database
nova-manage api_db sync
nova-manage db sync

# Restart service
service nova-api restart
service nova-consoleauth restart
service nova-conductor restart
service nova-novncproxy restart
