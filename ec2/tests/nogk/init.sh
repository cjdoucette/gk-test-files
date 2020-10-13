#!/bin/bash

if [ $# -ne 0 ]; then
  echo "usage: ./init.sh"
  echo "e.g.: ./init.sh"
  exit
fi

./ec2_send_command.sh client "sudo ip link set down ens6"
./ec2_send_command.sh tcp "sudo ip link set dev ens5 mtu 1500"
./ec2_send_command.sh tcp "sudo ip route del 172.31.3.200/32"
./ec2_send_command.sh tcp "git clone http://github.com/cjdoucette/raw-packets.git"
