#!/bin/bash

if [ $# -ne 2 ]; then
  echo "usage: ./run.sh traffic_rate experiment_length"
  echo "e.g.: ./run.sh 100mbps 30"
  exit
fi

EXP_RATE=$1
EXP_LEN=$2
EXP_NAME=bg$(echo "${@}" | tr [:blank:] _)

./ec2_send_command.sh client "sudo pkill sendRaw"
./ec2_send_command.sh client "rm -rf /home/ubuntu/client_ifconfig.txt"
./ec2_send_command.sh dest "rm -rf /home/ubuntu/server_ifconfig.txt"


./ec2_send_command.sh dest "nohup bash -c 'for i in $(eval echo {1..$((${EXP_LEN}+10))}); do ifconfig | grep ens5 --after-context=8 >> /home/ubuntu/server_ifconfig.txt && sleep 1; done' &>/dev/null &"
./ec2_send_command.sh client "nohup bash -c 'for i in $(eval echo {1..$((${EXP_LEN}+10))}); do ifconfig | grep ens5 --after-context=8 >> /home/ubuntu/client_ifconfig.txt && sleep 1; done' &>/dev/null &"

./ec2_send_command.sh client "nohup bash -c 'cd raw-packets; make; sudo ./sendRaw 0 ${EXP_RATE}' &>/dev/null &"

sleep ${EXP_LEN}

./ec2_send_command.sh client "sudo pkill sendRaw"
./ec2_get_file.sh client "/home/ubuntu/client_ifconfig.txt" results/${EXP_NAME}
./ec2_send_command.sh client "rm -rf /home/ubuntu/client_ifconfig.txt"

./ec2_get_file.sh dest "/home/ubuntu/server_ifconfig.txt" results/${EXP_NAME}
./ec2_send_command.sh dest "rm -rf /home/ubuntu/server_ifconfig.txt"
