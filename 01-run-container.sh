#!/bin/bash
docker run -i -t --rm --cpu-shares=100 --cpuset-cpus=0-7 --cap-add=SYS_ADMIN --cap-add=NET_ADMIN --cap-add=SYS_RESOURCE \
  rune:latest /bin/bash
