#!/bin/bash

if [ $# -ne 4 ]; then
  echo "usage: ./run.sh traffic_rate experiment_length ip_version proto"
  echo "e.g.: ./run.sh 1m 300 ipv4 tcp"
  exit
fi

EXP_RATE=$1
EXP_LEN=$2
EXP_IP=$3
EXP_PROTO=$4
EXP_NAME=iperf$(echo "${@}" | tr [:blank:] _)


./ec2_send_command.sh client "sudo pkill tcpdump"
./ec2_send_command.sh client "sudo pkill iperf3"
./ec2_send_command.sh client "rm -rf /home/ubuntu/client_dump.pcap"
./ec2_send_command.sh client "rm -rf /home/ubuntu/client_output.txt"

./ec2_send_command.sh dest "sudo pkill tcpdump"
./ec2_send_command.sh dest "sudo pkill iperf3"
./ec2_send_command.sh dest "rm -rf /home/ubuntu/server_dump.pcap"
./ec2_send_command.sh dest "rm -rf /home/ubuntu/server_output.txt"
./ec2_send_command.sh dest "rm -rf /home/ubuntu/server_ifconfig.txt"

./ec2_send_file.sh gk1_server "tests/iperf/config/add.lua" "gatekeeper/lua/examples/add.lua"
./ec2_send_file.sh gk1_server "tests/iperf/config/add6.lua" "gatekeeper/lua/examples/add6.lua"
./ec2_send_command.sh gk1_server "cd gatekeeper; sudo ./gkctl/gkctl lua/examples/add.lua" >/dev/null
./ec2_send_command.sh gk1_server "cd gatekeeper; sudo ./gkctl/gkctl lua/examples/add6.lua" >/dev/null

./ec2_send_command.sh dest "iperf3 -s -D -d --logfile /home/ubuntu/server_output.txt"
./ec2_send_command.sh dest "nohup bash -c 'sudo tcpdump -i ens6 -w /home/ubuntu/server_dump.pcap' &>/dev/null &"
./ec2_send_command.sh dest "nohup bash -c 'for i in $(eval echo {1..$((${EXP_LEN}+10))}); do ifconfig | grep ens6 --after-context=8 >> /home/ubuntu/server_ifconfig.txt && sleep 1; done' &>/dev/null &"

if [ "$EXP_IP" == "IPv4" ] || [ "$EXP_IP" == "ipv4" ]; then
  ./ec2_send_command.sh client "nohup bash -c 'sudo tcpdump -i ens5 ip and not port 22 -w /home/ubuntu/client_dump.pcap' &>/dev/null &"
  if [ "$EXP_PROTO" == "TCP" ] || [ "$EXP_PROTO" == "tcp" ]; then
    ./ec2_send_command.sh client "nohup iperf3 -c 172.31.1.43 --bind 172.31.0.94 --cport 43720 --length 64 -b ${EXP_RATE} -t ${EXP_LEN} --congestion cubic --logfile /home/ubuntu/client_output.txt &>/dev/null &"
  elif [ "$EXP_PROTO" == "UDP" ] || [ "$EXP_PROTO" == "udp" ]; then
    ./ec2_send_command.sh client "nohup iperf3 -c 172.31.1.43 -u --bind 172.31.0.94 --cport 43720 --length 64 -b ${EXP_RATE} -t ${EXP_LEN} --logfile /home/ubuntu/client_output.txt &>/dev/null &"
  else
    echo "No valid protocol selected"
  fi
elif [ "$EXP_IP" == "IPv6" ] || [ "$EXP_IP" == "ipv6" ]; then
  ./ec2_send_command.sh client "nohup bash -c 'sudo tcpdump -i ens5 ip6 -w /home/ubuntu/client_dump.pcap' &>/dev/null &"
  if [ "$EXP_PROTO" == "TCP" ] || [ "$EXP_PROTO" == "tcp" ]; then
    ./ec2_send_command.sh client "nohup iperf3 -c 2600:1f16:354:f701:795:5efd:5335:1439 --bind 2600:1f16:354:f700:795:5efd:5335:5678 --cport 43720 --length 64 -b ${EXP_RATE} -t ${EXP_LEN} --logfile /home/ubuntu/client_output.txt &>/dev/null &"
  elif [ "$EXP_PROTO" == "UDP" ] || [ "$EXP_PROTO" == "udp" ]; then
    ./ec2_send_command.sh client "nohup iperf3 -c 2600:1f16:354:f701:795:5efd:5335:1439 -u --bind 2600:1f16:354:f700:795:5efd:5335:5678 --cport 43720 --length 64 -b ${EXP_RATE} -t ${EXP_LEN} --logfile /home/ubuntu/client_output.txt &>/dev/null &"
  else
    echo "No valid protocol selected"
  fi
else
  echo "No valid IP version selected"
fi

sleep ${EXP_LEN}

./ec2_send_command.sh client "sudo pkill tcpdump"
./ec2_send_command.sh client "sudo pkill iperf3"
./ec2_get_file.sh client "/home/ubuntu/client_dump.pcap" results/${EXP_NAME}
./ec2_get_file.sh client "/home/ubuntu/client_output.txt" results/${EXP_NAME}
./ec2_send_command.sh client "rm -rf /home/ubuntu/client_dump.pcap"
./ec2_send_command.sh client "rm -rf /home/ubuntu/client_output.txt"

./ec2_send_command.sh dest "sudo pkill tcpdump"
./ec2_send_command.sh dest "sudo pkill iperf3"
./ec2_get_file.sh dest "/home/ubuntu/server_dump.pcap" results/${EXP_NAME}
./ec2_get_file.sh dest "/home/ubuntu/server_output.txt" results/${EXP_NAME}
./ec2_send_command.sh dest "rm -rf /home/ubuntu/server_dump.pcap"
./ec2_send_command.sh dest "rm -rf /home/ubuntu/server_output.txt"

./ec2_get_file.sh dest "/home/ubuntu/server_ifconfig.txt" results/${EXP_NAME}
./ec2_send_command.sh dest "rm -rf /home/ubuntu/server_ifconfig.txt"
