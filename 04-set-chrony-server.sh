#/bin/bash
echo server kr.pool.ntp.org iburst >> /etc/chrony/chrony/conf
service chrony restart
