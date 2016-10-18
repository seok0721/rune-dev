#!/bin/bash
docker build --cpu-shares=100 --cpuset-cpus=0-7 --tag rune:latest .
