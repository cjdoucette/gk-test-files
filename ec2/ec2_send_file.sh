#!/bin/bash

key_name="gatekeeper.pem"

if [ "$#" -ne 3 ]; then
    echo "You must enter an instance name, a local file, and remote destination"
    exit
fi

fname="ip_addrs.txt"
if [ ! -f ${fname} ]; then
  ./ec2_get_ip_addrs.sh
fi

ip_addr=$(cat ip_addrs.txt | grep "$1 " | awk '{print $2}')

if [ -e "${ip_addr}" ]; then
  echo "Can't find IP address"
  exit
fi

scp -i ${key_name} -o LogLevel=error -o StrictHostKeyChecking=no \
    "$2" ubuntu@ec2-$(echo "$ip_addr" | tr . -).us-east-2.compute.amazonaws.com:"$3"
