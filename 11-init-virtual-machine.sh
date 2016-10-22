#!/bin/bash
openstack flavor create --id 0 --vcpus 1 --ram 64 --disk 1 m1.nano
ssh-keygen -q -N ""
openstack keypair create --public-key ~/.ssh/id_rsa.pub mykey
openstack keypair list
