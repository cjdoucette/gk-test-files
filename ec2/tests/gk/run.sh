#!/bin/bash

if [ $# -ne 1 ]; then
  echo "usage: ./run.sh traffic_rate"
  echo "e.g.: ./run.sh {100mbps,500mbps,1-9gbps}"
  exit
fi

EXP_RATE=$1
EXP_NAME=gk$(echo "${@}" | tr [:blank:] _)

./ec2_send_command.sh dest "sudo pkill bash"		# ifconfig
./ec2_send_command.sh dest "sudo pkill nc"		# nc/tcp
./ec2_send_command.sh dest "sudo pkill python3"		# http
#./ec2_send_command.sh dest "sudo pkill tcpdump"
./ec2_send_command.sh dest "rm -rf /home/ubuntu/server_ifconfig.txt"
#./ec2_send_command.sh dest "rm -rf /home/ubuntu/server_dump.pcap"

./ec2_send_command.sh client "sudo pkill bash"		# ifconfig
./ec2_send_command.sh client "sudo pkill sendRawGk"
./ec2_send_command.sh client "rm -rf /home/ubuntu/client_ifconfig.txt"

./ec2_send_command.sh tcp "sudo pkill nc"		# nc/tcp
./ec2_send_command.sh tcp "sudo pkill curl"		# http
./ec2_send_command.sh tcp "sudo pkill send.sh"
./ec2_send_command.sh tcp "sudo pkill tcpdump"
./ec2_send_command.sh tcp "sudo rm -rf /home/ubuntu/raw-packets/legit/legit_log.txt"

# Add forwarding rule to Gatekeeper server.
./ec2_send_file.sh gk1_server "tests/gk/config/add.lua" "gatekeeper/lua/examples/add.lua"
./ec2_send_command.sh gk1_server "cd gatekeeper; sudo ./gkctl/gkctl lua/examples/add.lua" >/dev/null

# Start netcat server.
#./ec2_send_command.sh dest "nohup bash -c 'nc -k -l 1234' &>/dev/null &"
# Start HTTP server.
./ec2_send_command.sh dest "nohup bash -c 'python3 SimpleHTTPServerWithUpload.py' &>/dev/null &"
#./ec2_send_command.sh dest "nohup bash -c 'sudo tcpdump -i ens5 not port 22 -w /home/ubuntu/server_dump.pcap' &>/dev/null &"

# Start attack traffic.
if [ "$EXP_RATE" == "100mbps" ]; then
	./ec2_send_command.sh client "nohup bash -c 'cd raw-packets; sudo make; sudo ./sendRawGk 0 ${EXP_RATE}' &>/dev/null &"
elif [ "$EXP_RATE" == "500mbps" ]; then
	./ec2_send_command.sh client "nohup bash -c 'cd raw-packets; sudo make; sudo ./sendRawGk 0 ${EXP_RATE}' &>/dev/null &"
elif [ "$EXP_RATE" == "1gbps" ]; then
	for i in {0..1}
	do
		./ec2_send_command.sh client "nohup bash -c 'cd raw-packets; sudo make; sudo ./sendRawGk ${i} ${EXP_RATE}' &>/dev/null &"
	done
elif [ "$EXP_RATE" == "2gbps" ]; then
	for i in {0..1}
	do
		./ec2_send_command.sh client "nohup bash -c 'cd raw-packets; sudo make; sudo ./sendRawGk ${i} ${EXP_RATE}' &>/dev/null &"
	done
elif [ "$EXP_RATE" == "3gbps" ]; then
	for i in {0..2}
	do
		./ec2_send_command.sh client "nohup bash -c 'cd raw-packets; sudo make; sudo ./sendRawGk ${i} ${EXP_RATE}' &>/dev/null &"
	done
elif [ "$EXP_RATE" == "4gbps" ]; then
	for i in {0..3}
	do
		./ec2_send_command.sh client "nohup bash -c 'cd raw-packets; sudo make; sudo ./sendRawGk ${i} ${EXP_RATE}' &>/dev/null &"
	done
elif [ "$EXP_RATE" == "5gbps" ]; then
	for i in {0..4}
	do
		./ec2_send_command.sh client "nohup bash -c 'cd raw-packets; sudo make; sudo ./sendRawGk ${i} ${EXP_RATE}' &>/dev/null &"
	done
elif [ "$EXP_RATE" == "6gbps" ]; then
	for i in {0..5}
	do
		./ec2_send_command.sh client "nohup bash -c 'cd raw-packets; sudo make; sudo ./sendRawGk ${i} ${EXP_RATE}' &>/dev/null &"
	done
elif [ "$EXP_RATE" == "7gbps" ]; then
	for i in {0..6}
	do
		./ec2_send_command.sh client "nohup bash -c 'cd raw-packets; sudo make; sudo ./sendRawGk ${i} ${EXP_RATE}' &>/dev/null &"
	done
elif [ "$EXP_RATE" == "8gbps" ]; then
	for i in {0..7}
	do
		./ec2_send_command.sh client "nohup bash -c 'cd raw-packets; sudo make; sudo ./sendRawGk ${i} ${EXP_RATE}' &>/dev/null &"
	done
elif [ "$EXP_RATE" == "9gbps" ]; then
	for i in {0..7}
	do
		./ec2_send_command.sh client "nohup bash -c 'cd raw-packets; sudo make; sudo ./sendRawGk ${i} ${EXP_RATE}' &>/dev/null &"
	done
	./ec2_send_command.sh client "nohup bash -c 'cd raw-packets; sudo make; sudo ./sendRawGk 0 ${EXP_RATE}' &>/dev/null &"
elif [ "$EXP_RATE" == "10gbps" ]; then
	for i in {0..7}
	do
		./ec2_send_command.sh client "nohup bash -c 'cd raw-packets; sudo make; sudo ./sendRawGk ${i} ${EXP_RATE}' &>/dev/null &"
	done
	./ec2_send_command.sh client "nohup bash -c 'cd raw-packets; sudo make; sudo ./sendRawGk 0 ${EXP_RATE}' &>/dev/null &"
	./ec2_send_command.sh client "nohup bash -c 'cd raw-packets; sudo make; sudo ./sendRawGk 1 ${EXP_RATE}' &>/dev/null &"
	./ec2_send_command.sh client "nohup bash -c 'cd raw-packets; sudo make; sudo ./sendRawGk 2 ${EXP_RATE}' &>/dev/null &"
fi

# Start capturing attacker TX rate and server RX rate.
./ec2_send_command.sh client "nohup bash -c 'while true; do ifconfig | grep ens5 --after-context=8 >> /home/ubuntu/client_ifconfig.txt && sleep 1; done' &>/dev/null &"
./ec2_send_command.sh dest "nohup bash -c 'while true; do ifconfig | grep ens3 --after-context=8 >> /home/ubuntu/server_ifconfig.txt && date >> /home/ubuntu/server_ifconfig.txt && sleep 5; done' &>/dev/null &"

# Let attackers get up to speed.
sleep 20

# Start legitimate client.
./ec2_send_command.sh tcp "nohup bash -c 'sudo tcpdump -i ens5 not port 22 -w /home/ubuntu/legit_dump.pcap' &>/dev/null &"
./ec2_send_command.sh tcp "cd raw-packets/legit && ./send.sh"

echo "Cleaning up ..."
./ec2_send_command.sh dest "sudo pkill bash"		# ifconfig
./ec2_send_command.sh dest "sudo pkill nc"		# nc/tcp
./ec2_send_command.sh dest "sudo pkill python3"		# http
#./ec2_send_command.sh dest "sudo pkill tcpdump"
./ec2_get_file.sh dest "/home/ubuntu/server_ifconfig.txt" results/${EXP_NAME}
./ec2_send_command.sh dest "rm -rf /home/ubuntu/server_ifconfig.txt"
#./ec2_get_file.sh dest "/home/ubuntu/server_dump.pcap" results/${EXP_NAME}
#./ec2_send_command.sh dest "rm -rf /home/ubuntu/server_dump.pcap"

./ec2_send_command.sh client "sudo pkill bash"		# ifconfig
./ec2_send_command.sh client "sudo pkill sendRawGk"
./ec2_get_file.sh client "/home/ubuntu/client_ifconfig.txt" results/${EXP_NAME}
./ec2_send_command.sh client "rm -rf /home/ubuntu/client_ifconfig.txt"

./ec2_send_command.sh tcp "sudo pkill nc"		# nc/tcp
./ec2_send_command.sh tcp "sudo pkill curl"		# http
./ec2_send_command.sh tcp "sudo pkill send.sh"
./ec2_send_command.sh tcp "sudo pkill tcpdump"
./ec2_send_command.sh tcp "sudo chmod ogu+r /home/ubuntu/raw-packets/legit/legit_log.txt"
./ec2_get_file.sh tcp "/home/ubuntu/raw-packets/legit/legit_log.txt" results/${EXP_NAME}
./ec2_send_command.sh tcp "sudo rm -rf /home/ubuntu/raw-packets/legit/legit_log.txt"
./ec2_get_file.sh tcp "/home/ubuntu/legit_dump.pcap" results/${EXP_NAME}
./ec2_send_command.sh tcp "rm -rf /home/ubuntu/legit_dump.pcap"
