#!/bin/bash

if [ $# -ne 2 ]; then
  echo "usage: ./init.sh exp_name traffic_rate"
  echo "e.g.: ./init.sh nogk {100mibps,500mibps,1-9gibps}"
  exit
fi

EXP_POLICY=$3

# Don't use interface (for back-to-front tests).
./ec2_send_command.sh client2 "sudo ip link set down ens6"

# Encapsulate packets from the legitimate client.
#./ec2_send_command.sh tcp "sudo ip link set dev ens5 mtu 1520"
#./ec2_send_command.sh tcp "sudo ip link add ipip0 type ipip external"
#./ec2_send_command.sh tcp "sudo ip link set up dev ipip0"
./ec2_send_command.sh tcp "sudo ip route del 172.31.3.200/32"
#./ec2_send_command.sh tcp "sudo ip route add 172.31.3.200/32 encap ip id 1234 dst 172.31.1.43 dev ipip0 mtu 1500"

# Get testing software.
./ec2_send_command.sh tcp "git clone http://github.com/cjdoucette/raw-packets.git"
