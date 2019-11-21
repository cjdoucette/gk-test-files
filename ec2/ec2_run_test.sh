#!/bin/bash

if [ $# -ne 2 ]; then
  echo "usage: ./ec2_run_test.sh experiment_name experiment_length"
  echo "e.g.: ./ec2_run_test.sh patch1 300"
  exit
fi

EXP_NAME=$1
EXP_LEN=$2

# Create directory for experiment results.
mkdir -p $EXP_NAME

#
# Cleanup any state from previous experiments.
#

./ec2_send_command.sh gt_server "sudo rm -rf /home/ubuntu/gatekeeper/grantor.log"
./ec2_send_command.sh gt_server "sudo pkill gatekeeper"

./ec2_send_command.sh gk1_server "sudo rm -rf /home/ubuntu/gatekeeper/gatekeeper.log"
./ec2_send_command.sh gk1_server "sudo pkill gatekeeper"

./ec2_send_command.sh dest "sudo pkill iperf3"
./ec2_send_command.sh dest "rm -rf /home/ubuntu/iperf3_output.txt"

./ec2_send_command.sh client "sudo pkill iperf3"

#
# Start Gatekeeper testbed.
#

./ec2_send_command.sh gk1_server "bash -c 'cd gatekeeper; (sudo nohup ./build/gatekeeper -- -l gatekeeper.log &>/dev/null) &'"
./ec2_send_command.sh gt_server "bash -c 'cd gatekeeper; (sudo nohup ./build/gatekeeper -- -l grantor.log &>/dev/null) &'"

sleep 10

./ec2_send_command.sh gk1_server "cd gatekeeper; sudo ./gkctl/gkctl lua/examples/add.lua"
./ec2_send_command.sh gk1_server "cd gatekeeper; sudo ./gkctl/gkctl lua/examples/add6.lua"

#
# Run iperf3 over UDP.
#

./ec2_send_command.sh dest "iperf3 -s -D --logfile /home/ubuntu/iperf3_output.txt"
./ec2_send_command.sh client "iperf3 -c 172.31.1.43 -u --bind 172.31.0.94 --cport 43720 --length 64 -b 100M -t ${EXP_LEN}"

#
# Clean up experiment and fetch logs.
#

./ec2_send_command.sh gt_server "sudo pkill gatekeeper"
./ec2_send_command.sh gk1_server "sudo pkill gatekeeper"
./ec2_send_command.sh dest "sudo pkill iperf3"
./ec2_send_command.sh client "sudo pkill iperf3"

./ec2_send_command.sh gt_server "sudo chmod ogu+r /home/ubuntu/gatekeeper/grantor.log"
./ec2_get_file.sh gt_server "/home/ubuntu/gatekeeper/grantor.log" ${EXP_NAME}
./ec2_send_command.sh gk1_server "sudo chmod ogu+r /home/ubuntu/gatekeeper/gatekeeper.log"
./ec2_get_file.sh gk1_server "/home/ubuntu/gatekeeper/gatekeeper.log" ${EXP_NAME}
./ec2_get_file.sh dest "/home/ubuntu/iperf3_output.txt" ${EXP_NAME}

./ec2_send_command.sh gt_server "sudo rm -rf /home/ubuntu/gatekeeper/grantor.log"
./ec2_send_command.sh gk1_server "sudo rm -rf /home/ubuntu/gatekeeper/gatekeeper.log"
./ec2_send_command.sh dest "rm -rf /home/ubuntu/iperf3_output.txt"
