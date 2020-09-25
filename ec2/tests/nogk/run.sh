#!/bin/bash

if [ $# -ne 2 ]; then
  echo "usage: ./run.sh traffic_rate experiment_length"
  echo "e.g.: ./run.sh 100mbps 30"
  exit
fi

EXP_RATE=$1
EXP_LEN=$2
EXP_NAME=nogk$(echo "${@}" | tr [:blank:] _)

./ec2_send_command.sh client "sudo pkill sendRaw"
./ec2_send_command.sh dest "sudo pkill nc"
./ec2_send_command.sh client "rm -rf /home/ubuntu/client_ifconfig.txt"
./ec2_send_command.sh dest "rm -rf /home/ubuntu/server_ifconfig.txt"

./ec2_send_command.sh dest "nohup bash -c 'nc -k -l 1234' &>/dev/null &"

if [ "$EXP_RATE" == "100mbps" ]; then
	./ec2_send_command.sh client "nohup bash -c 'cd raw-packets; sudo make; sudo ./sendRaw 0 ${EXP_RATE}' &>/dev/null &"
elif [ "$EXP_RATE" == "500mbps" ]; then
	./ec2_send_command.sh client "nohup bash -c 'cd raw-packets; sudo make; sudo ./sendRaw 0 ${EXP_RATE}' &>/dev/null &"
elif [ "$EXP_RATE" == "1gbps" ]; then
	for i in {0..1}
	do
		./ec2_send_command.sh client "nohup bash -c 'cd raw-packets; sudo make; sudo ./sendRaw ${i} ${EXP_RATE}' &>/dev/null &"
	done
elif [ "$EXP_RATE" == "2gbps" ]; then
	for i in {0..1}
	do
		./ec2_send_command.sh client "nohup bash -c 'cd raw-packets; sudo make; sudo ./sendRaw ${i} ${EXP_RATE}' &>/dev/null &"
	done
elif [ "$EXP_RATE" == "3gbps" ]; then
	for i in {0..2}
	do
		./ec2_send_command.sh client "nohup bash -c 'cd raw-packets; sudo make; sudo ./sendRaw ${i} ${EXP_RATE}' &>/dev/null &"
	done
elif [ "$EXP_RATE" == "4gbps" ]; then
	for i in {0..3}
	do
		./ec2_send_command.sh client "nohup bash -c 'cd raw-packets; sudo make; sudo ./sendRaw ${i} ${EXP_RATE}' &>/dev/null &"
	done
elif [ "$EXP_RATE" == "5gbps" ]; then
	for i in {0..4}
	do
		./ec2_send_command.sh client "nohup bash -c 'cd raw-packets; sudo make; sudo ./sendRaw ${i} ${EXP_RATE}' &>/dev/null &"
	done
elif [ "$EXP_RATE" == "6gbps" ]; then
	for i in {0..5}
	do
		./ec2_send_command.sh client "nohup bash -c 'cd raw-packets; sudo make; sudo ./sendRaw ${i} ${EXP_RATE}' &>/dev/null &"
	done
elif [ "$EXP_RATE" == "7gbps" ]; then
	for i in {0..6}
	do
		./ec2_send_command.sh client "nohup bash -c 'cd raw-packets; sudo make; sudo ./sendRaw ${i} ${EXP_RATE}' &>/dev/null &"
	done
elif [ "$EXP_RATE" == "8gbps" ]; then
	for i in {0..7}
	do
		./ec2_send_command.sh client "nohup bash -c 'cd raw-packets; sudo make; sudo ./sendRaw ${i} ${EXP_RATE}' &>/dev/null &"
	done
elif [ "$EXP_RATE" == "9gbps" ]; then
	for i in {0..7}
	do
		./ec2_send_command.sh client "nohup bash -c 'cd raw-packets; sudo make; sudo ./sendRaw ${i} ${EXP_RATE}' &>/dev/null &"
	done
	./ec2_send_command.sh client "nohup bash -c 'cd raw-packets; sudo make; sudo ./sendRaw 0 ${EXP_RATE}' &>/dev/null &"
elif [ "$EXP_RATE" == "10gbps" ]; then
	for i in {0..7}
	do
		./ec2_send_command.sh client "nohup bash -c 'cd raw-packets; sudo make; sudo ./sendRaw ${i} ${EXP_RATE}' &>/dev/null &"
	done
	./ec2_send_command.sh client "nohup bash -c 'cd raw-packets; sudo make; sudo ./sendRaw 0 ${EXP_RATE}' &>/dev/null &"
	./ec2_send_command.sh client "nohup bash -c 'cd raw-packets; sudo make; sudo ./sendRaw 1 ${EXP_RATE}' &>/dev/null &"
	./ec2_send_command.sh client "nohup bash -c 'cd raw-packets; sudo make; sudo ./sendRaw 2 ${EXP_RATE}' &>/dev/null &"
fi

# Let senders get up to speed.
sleep 30

./ec2_send_command.sh client "nohup bash -c 'for i in $(eval echo {1..$((${EXP_LEN}+6))}); do ifconfig | grep ens5 --after-context=8 >> /home/ubuntu/client_ifconfig.txt && sleep 1; done' &>/dev/null &"
./ec2_send_command.sh dest "nohup bash -c 'for i in $(eval echo {1..$((${EXP_LEN}/5))}); do ifconfig | grep ens5 --after-context=8 >> /home/ubuntu/server_ifconfig.txt && date >> /home/ubuntu/server_ifconfig.txt && sleep 5; done' &>/dev/null &"

./ec2_send_command.sh tcp "nohup bash -c 'cd raw-packets/legit && ./send.sh' &>/dev/null &"
sleep ${EXP_LEN}

./ec2_send_command.sh client "sudo pkill sendRaw"
./ec2_send_command.sh dest "sudo pkill nc"
./ec2_send_command.sh tcp "sudo pkill nc"
./ec2_send_command.sh tcp "sudo pkill send.sh"
./ec2_send_command.sh tcp "sudo pkill tcpdump"

./ec2_get_file.sh dest "/home/ubuntu/server_ifconfig.txt" results/${EXP_NAME}
./ec2_get_file.sh client "/home/ubuntu/client_ifconfig.txt" results/${EXP_NAME}
./ec2_get_file.sh tcp "/home/ubuntu/raw-packets/legit/output.txt" results/${EXP_NAME}

./ec2_send_command.sh dest "rm -rf /home/ubuntu/server_ifconfig.txt"
./ec2_send_command.sh client "rm -rf /home/ubuntu/client_ifconfig.txt"
./ec2_send_command.sh tcp "rm -rf /home/ubuntu/raw-packets/legit/output.txt"
