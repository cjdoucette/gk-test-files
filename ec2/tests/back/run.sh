#!/bin/bash

if [ $# -ne 0 ]; then
  echo "usage: ./run.sh"
  echo "e.g.: ./run.sh"
  exit
fi

EXP_NAME=back

./ec2_send_command.sh client "sudo pkill tcpdump"
./ec2_send_command.sh client "rm -rf /home/ubuntu/client_dump.txt"

./ec2_send_file.sh gk1_server "tests/back/config/add.lua" "gatekeeper/lua/examples/add.lua"
./ec2_send_command.sh gk1_server "cd gatekeeper; sudo ./gkctl/gkctl lua/examples/add.lua" >/dev/null

./ec2_send_command.sh client "nohup bash -c 'sudo tcpdump -nni ens6 -XX -xx udp > /home/ubuntu/client_dump.txt' &>/dev/null &"

# Send from destination.
sleep 5
./ec2_send_command.sh dest "echo -n 'Hello, world!' >/dev/udp/172.31.2.102/8080"
sleep 5

./ec2_send_command.sh client "sudo pkill tcpdump"
./ec2_get_file.sh client "/home/ubuntu/client_dump.txt" results/${EXP_NAME}
./ec2_send_command.sh client "rm -rf /home/ubuntu/client_dump.txt"
