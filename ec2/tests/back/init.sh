#!/bin/bash

if [ $# -ne 0 ]; then
  echo "usage: ./init.sh"
  echo "e.g.: ./init.sh"
  exit
fi

./ec2_send_command.sh client "sudo ip addr add 172.31.3.60/24 dev ens6"
./ec2_send_command.sh client "sudo ip addr add 2600:1f16:354:f703:795:5efd:5335:5678/64 dev ens6"
./ec2_send_command.sh client "sudo ip link set up dev ens6"
./ec2_send_command.sh client "sudo ip link set mtu 1500 dev ens6"
