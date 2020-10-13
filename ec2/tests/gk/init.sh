#!/bin/bash

if [ $# -ne 0 ]; then
  echo "usage: ./init.sh"
  echo "e.g.: ./init.sh"
  exit
fi

# Add policy file to Grantor.
./ec2_send_file.sh gt_server "tests/gk/config/policy.lua" "gatekeeper/lua/examples/policy.lua"

# Don't use interface (for back-to-front tests).
./ec2_send_command.sh client "sudo ip link set down ens6"

# Encapsulate packets from the legitimate client.
./ec2_send_command.sh tcp "sudo ip link set dev ens5 mtu 1520"
./ec2_send_command.sh tcp "sudo ip link add ipip0 type ipip external"
./ec2_send_command.sh tcp "sudo ip link set up dev ipip0"
./ec2_send_command.sh tcp "sudo ip route del 172.31.3.200/32"
./ec2_send_command.sh tcp "sudo ip route add 172.31.3.200/32 encap ip id 1234 dst 172.31.1.43 dev ipip0 mtu 1500"

# Get testing software.
./ec2_send_command.sh tcp "git clone http://github.com/cjdoucette/raw-packets.git"
