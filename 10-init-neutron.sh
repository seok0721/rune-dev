#!/bin/bash

# Initialize environment
if [ -z `grep -r controller /etc/hosts` ]; then echo 127.0.0.1 controller >> /etc/hosts; fi
if [ -z `pidof mysqld` ]; then service mysql start; fi
if [ -z `pidof apache2` ]; then service apache2 start; fi
source /etc/admin-openrc
source /root/root-openrc
unset OS_TOKEN

echo "CREATE DATABASE neutron" | mysql
echo "GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'localhost' IDENTIFIED BY '$NEUTRON_DBPASS'" | mysql
echo "GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'%' IDENTIFIED BY '$NEUTRON_DBPASS'" | mysql

openstack user create --domain default --password $ADMIN_PASS neutron
openstack role add --project service --user neutron admin
openstack service create --name neutron --description "OpenStack Networking" network
openstack endpoint create --region RegionOne network public http://controller:9696
openstack endpoint create --region RegionOne network internal http://controller:9696
openstack endpoint create --region RegionOne network admin http://controller:9696

METADATA_SECRET=0000

sed -i -- "s/^#nova_metadata_ip =.*/nova_metadata_ip = controller/g" /etc/neutron/metadata_agent.ini
sed -i -- "s/^#metadata_proxy_shared_secret =.*/metadata_proxy_shared_secret = $METADATA_SECRET/g" /etc/neutron/metadata_agent.ini

echo "
[neutron]
url = http://controller:9696
auth_url = http://controller:35357
auth_type = password
project_domain_name = default
user_domain_name = default
region_name = RegionOne
project_name = service
username = neutron
password = $NEUTRON_PASS

service_metadata_proxy = True
metadata_proxy_shared_secret = $METADATA_SECRET" >> /etc/nova/nova.conf

echo 1
sed -i -- "s/^\[DEFAULT\]/[DEFAULT]\n\nallow_overlapping_ips = True\nauth_strategy = keystone\ncore_plugin = ml2\nrpc_backend = rabbit\nservice_plugins =\nnotify_nova_on_port_status_changes = True\nnotify_nova_on_port_data_changes = True\n/g" /etc/neutron/neutron.conf
sed -i -- "s/^connection =.*/connection = mysql+pymysql:\/\/neutron:$NEUTRON_DBPASS@controller\/neutron\n/g" /etc/neutron/neutron.conf
sed -i -- "s/^\[oslo_messaging_rabbit\]/[oslo_messaging_rabbit]\n\nrabbit_host = controller\nrabbit_userid = openstack\nrabbit_password = $RABBIT_PASS\n/g" /etc/neutron/neutron.conf
sed -i -- "s/^\[keystone_authtoken\]/[keystone_authtoken]\n\nauth_uri = http:\/\/controller:5000\nauth_url = http:\/\/controller:35357\nmemcached_servers = controller:11211\nauth_type = password\nproject_domain_name = default\nuser_domain_name = default\nproject_name = service\nusername = neutron\npassword = $NEUTRON_PASS/g" /etc/neutron/neutron.conf
sed -i -- "s/^\[nova\]/[nova]\n\nauth_url = http:\/\/controller:35357\nauth_type = password\nproject_domain_name = default\nuser_domain_name = default\nregion_name = RegionOne\nproject_name = service\nusername = nova\npassword = $NOVA_PASS\n/g" /etc/neutron/neutron.conf

# /etc/neutron/plugins/ml2/ml2_conf.ini
echo 2
sed -i -- "s/\[ml2\]/[ml2]\n\ntype_drivers = flat,vlan,vxlan\ntenant_network_types = vxlan\nmechanism_drivers = linuxbridge,l2population\nextension_drivers = port_security\n/g" /etc/neutron/plugins/ml2/ml2_conf.ini
sed -i -- "s/\[ml2_type_flat\]/[ml2_type_flat]\n\nflat_networks = provider\nvni_ranges = 1:1000\nenable_ipset = True\n/g" /etc/neutron/plugins/ml2/ml2_conf.ini
sed -i -- "s/\[securitygroup\]/[securitygroup]\n\nenable_ipset = True\n/g" /etc/neutron/plugins/ml2/ml2_conf.ini

PROVIDER_INTERFACE_NAME=eth0
OVERLAY_INTERFACE_IP_ADDRESS=0.0.0.0
echo 3
sed -i -- "s/\[linux_bridge\]/[linux_bridge]\n\nphysical_interface_mappings = provider:$PROVIDER_INTERFACE_NAME\n/g" /etc/neutron/plugins/ml2/linuxbridge_agent.ini
sed -i -- "s/\[vxlan\]/[vxlan]\n\nenable_vxlan = True\nlocal_ip = $OVERLAY_INTERFACE_IP_ADDRESS\nl2_population = True\n/g" /etc/neutron/plugins/ml2/linuxbridge_agent.ini
sed -i -- "s/\[securitygroup\]/[securitygroup]\n\nenable_security_group = True\nfirewall_driver = neutron.agent.linux.iptables_firewall.IptablesFirewallDriver\n/g" /etc/neutron/plugins/ml2/linuxbridge_agent.ini

sed -i -- "s/\[DEFAULT\]/[DEFAULT]\n\ninterface_driver = neutron.agent.linux.interface.BridgeInterfaceDriver\nexternal_network_bridge =\n/g" /etc/neutron/l3_agent.ini
sed -i -- "s/\[DEFAULT\]/[DEFAULT]\n\ninterface_driver = neutron.agent.linux.interface.BridgeInterfaceDriver\ndhcp_driver = neutron.agent.linux.dhcp.Dnsmasq\nenable_isolated_metadata = True\n/g" /etc/neutron/dhcp_agent.ini

neutron-db-manage --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head

service nova-api restart
service neutron-server restart
service neutron-linuxbridge-agent restart
service neutron-dhcp-agent restart
service neutron-metadata-agent restart
service neutron-l3-agent restart
