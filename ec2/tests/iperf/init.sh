#!/bin/bash

if [ $# -ne 0 ]; then
  echo "usage: ./init.sh"
  echo "e.g.: ./init.sh"
  exit
fi

./ec2_send_command.sh client "sudo ip link set down ens6"
