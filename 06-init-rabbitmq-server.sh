#!/bin/bash
source /etc/admin-openrc
apt-get -y install rabbitmq-server
source /etc/admin-openrc; rabbitmqctl add_user openstack $RABBIT_PASS
rabbitmqctl set_permissions openstack ".*" ".*" ".*"
service rabbitmq-server restart
