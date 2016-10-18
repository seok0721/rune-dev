#!/bin/bash
grep -r controller /etc/hosts

if [ $? -ne 0 ]; then
  echo '127.0.0.1 controller' >> /etc/hosts
fi
