#!/bin/bash
if [ -z `pidof rabbitmq-server` ]; then service rabbitmq-server start; fi
source /etc/admin-openrc
rabbitmqctl add_user openstack $RABBIT_PASS
rabbitmqctl set_permissions openstack ".*" ".*" ".*"
