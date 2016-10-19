#!/bin/bash
echo 127.0.0.1 controller >> /etc/hosts
service chrony restart
service mysql restart
service mongodb restart
service rabbitmq-server restart
service memcached restart
service apache2 restart

service glance-api restart
service glance-registry restart

service nova-api restart
service nova-consoleauth restart
service nova-conductor restart
service nova-novncproxy restart
service nova-compute restart
