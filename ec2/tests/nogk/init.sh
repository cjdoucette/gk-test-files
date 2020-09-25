#!/bin/bash

if [ $# -ne 0 ]; then
  echo "usage: ./init.sh"
  echo "e.g.: ./init.sh"
  exit
fi

./ec2_send_command.sh client "sudo ip link set down ens6"
./ec2_send_command.sh client "sudo ip route del 172.31.3.200/32 encap bpf xmit obj /ebpf-encap/ipip.bpf sec ipip_encap dev ens5"
./ec2_send_command.sh tcp "git clone http://github.com/cjdoucette/raw-packets.git"
