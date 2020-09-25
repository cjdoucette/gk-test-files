#!/bin/bash

if [ $# -ne 2 ]; then
  echo "usage: ./run.sh traffic_rate experiment_length"
  echo "e.g.: ./run.sh {100mbps} 30"
  exit
fi

EXP_RATE=$1
EXP_LEN=$2
EXP_NAME=bgiperf3$(echo "${@}" | tr [:blank:] _)

./ec2_send_command.sh client "sudo pkill iperf3"
./ec2_send_command.sh client "rm -rf /home/ubuntu/client_output.txt"
./ec2_send_command.sh client "rm -rf /home/ubuntu/client_ifconfig.txt"

./ec2_send_command.sh dest "sudo pkill iperf3"
./ec2_send_command.sh dest "rm -rf /home/ubuntu/server_output.txt"
./ec2_send_command.sh dest "rm -rf /home/ubuntu/server_ifconfig.txt"

for i in {1..9}
do
	./ec2_send_command.sh dest "iperf3 -s -D -d -p 520${i} --logfile /home/ubuntu/server_output.txt"
done

./ec2_send_command.sh dest "nohup bash -c 'for i in $(eval echo {1..$((${EXP_LEN}+5))}); do ifconfig | grep ens5 --after-context=8 >> /home/ubuntu/server_ifconfig.txt && sleep 1; done' &>/dev/null &"
./ec2_send_command.sh client "nohup bash -c 'for i in $(eval echo {1..$((${EXP_LEN}+5))}); do ifconfig | grep ens5 --after-context=8 >> /home/ubuntu/client_ifconfig.txt && sleep 1; done' &>/dev/null &"

if [ "$EXP_RATE" == "100mbps" ]; then
	for i in {1..8}
	do
#		./ec2_send_command.sh client "nohup iperf3 -c 172.31.3.200 --bind 172.31.0.94 -p 520${i} -t ${EXP_LEN} -P 128 -b 100K --congestion cubic --length 256 --logfile /home/ubuntu/client_output.txt &>/dev/null &"
		./ec2_send_command.sh client "nohup iperf3 -c 172.31.3.200 --bind 172.31.0.94 -p 520${i} -t ${EXP_LEN} -P 128 -b 100K -u --length 256 --logfile /home/ubuntu/client_output.txt &>/dev/null &"
	done
elif [ "$EXP_RATE" == "500mbps" ]; then
	for i in {1..8}
	do
#		./ec2_send_command.sh client "nohup iperf3 -c 172.31.3.200 --bind 172.31.0.94 -p 520${i} -t ${EXP_LEN} -P 128 -b 500K --congestion cubic --length 256 --logfile /home/ubuntu/client_output.txt &>/dev/null &"
		./ec2_send_command.sh client "nohup iperf3 -c 172.31.3.200 --bind 172.31.0.94 -p 520${i} -t ${EXP_LEN} -P 128 -b 500K -u --length 256 --logfile /home/ubuntu/client_output.txt &>/dev/null &"
	done
elif [ "$EXP_RATE" == "1gbps" ]; then
	for i in {1..8}
	do
#		./ec2_send_command.sh client "nohup iperf3 -c 172.31.3.200 --bind 172.31.0.94 -p 520${i} -t ${EXP_LEN} -P 128 -b 1M --congestion cubic --length 256 --logfile /home/ubuntu/client_output.txt &>/dev/null &"
		./ec2_send_command.sh client "nohup iperf3 -c 172.31.3.200 --bind 172.31.0.94 -p 520${i} -t ${EXP_LEN} -P 128 -b 1M -u --length 256 --logfile /home/ubuntu/client_output.txt &>/dev/null &"
	done
elif [ "$EXP_RATE" == "2gbps" ]; then
	for i in {1..8}
	do
#		./ec2_send_command.sh client "nohup iperf3 -c 172.31.3.200 --bind 172.31.0.94 -p 520${i} -t ${EXP_LEN} -P 128 -b 2M --congestion cubic --length 256 --logfile /home/ubuntu/client_output.txt &>/dev/null &"
		./ec2_send_command.sh client "nohup iperf3 -c 172.31.3.200 --bind 172.31.0.94 -p 520${i} -t ${EXP_LEN} -P 128 -b 2M -u --length 256 --logfile /home/ubuntu/client_output.txt &>/dev/null &"
	done
elif [ "$EXP_RATE" == "5gbps" ]; then
	for i in {1..8}
	do
#		./ec2_send_command.sh client "nohup iperf3 -c 172.31.3.200 --bind 172.31.0.94 -p 520${i} -t ${EXP_LEN} -P 128 -b 5M --congestion cubic --length 512 --logfile /home/ubuntu/client_output.txt &>/dev/null &"
		./ec2_send_command.sh client "nohup iperf3 -c 172.31.3.200 --bind 172.31.0.94 -p 520${i} -t ${EXP_LEN} -P 128 -b 5M -u --length 512 --logfile /home/ubuntu/client_output.txt &>/dev/null &"
	done
elif [ "$EXP_RATE" == "10gbps" ]; then
	for i in {1..8}
	do
#		./ec2_send_command.sh client "nohup iperf3 -c 172.31.3.200 --bind 172.31.0.94 -p 520${i} -t ${EXP_LEN} -P 128 -b 10M --congestion cubic --length 768 --logfile /home/ubuntu/client_output.txt &>/dev/null &"
		./ec2_send_command.sh client "nohup iperf3 -c 172.31.3.200 --bind 172.31.0.94 -p 520${i} -t ${EXP_LEN} -P 128 -b 10M -u --length 768 --logfile /home/ubuntu/client_output.txt &>/dev/null &"
	done
fi

sleep 1
./ec2_send_command.sh client "nohup iperf3 -c 172.31.3.200 --bind 172.31.0.94 -p 5209 -b 100K --congestion cubic --length 256 --logfile /home/ubuntu/client_output.txt &>/dev/null &"

sleep ${EXP_LEN}

./ec2_send_command.sh client "sudo pkill iperf3"
./ec2_get_file.sh client "/home/ubuntu/client_output.txt" results/${EXP_NAME}
./ec2_send_command.sh client "rm -rf /home/ubuntu/client_output.txt"
./ec2_get_file.sh client "/home/ubuntu/client_ifconfig.txt" results/${EXP_NAME}
./ec2_send_command.sh client "rm -rf /home/ubuntu/client_ifconfig.txt"

./ec2_send_command.sh dest "sudo pkill iperf3"
./ec2_get_file.sh dest "/home/ubuntu/server_output.txt" results/${EXP_NAME}
./ec2_send_command.sh dest "rm -rf /home/ubuntu/server_output.txt"
./ec2_get_file.sh dest "/home/ubuntu/server_ifconfig.txt" results/${EXP_NAME}
./ec2_send_command.sh dest "rm -rf /home/ubuntu/server_ifconfig.txt"
