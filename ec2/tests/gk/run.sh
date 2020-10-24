#!/bin/bash

if [ $# -ne 3 ]; then
  echo "usage: ./run.sh exp_name traffic_rate policy"
  echo "e.g.: ./run.sh gk {100mibps,500mibps,1-9gibps}"
  exit
fi

EXP_NAME=$1
EXP_RATE=$2
EXP_POLICY=$3
RESULTS_NAME=$(echo "${@:2}" | tr [:blank:] _)

./ec2_get_file.sh dest "/home/ubuntu/server_ifconfig.txt" results/${EXP_NAME}/${RESULTS_NAME}/server_ifconfig_prev.txt
./ec2_send_command.sh dest "rm -rf /home/ubuntu/server_ifconfig.txt"

./ec2_send_command.sh client "sudo pkill bash"		# ifconfig
./ec2_send_command.sh client "sudo pkill sendRawGk"
./ec2_send_command.sh client "rm -rf /home/ubuntu/client_ifconfig.txt"

./ec2_send_command.sh tcp "sudo pkill nc"		# nc/tcp
./ec2_send_command.sh tcp "sudo pkill curl"		# http
./ec2_send_command.sh tcp "sudo pkill send.sh"
./ec2_send_command.sh tcp "sudo pkill tcpdump"
./ec2_send_command.sh tcp "sudo rm -rf /home/ubuntu/raw-packets/legit/legit_log.txt"

# Run Gatekeeper and Grantor.
./ec2_send_command.sh gk1_server "bash -c 'cd gatekeeper; (sudo nohup ./build/gatekeeper -- -l gatekeeper.log &>/dev/null) &'"
./ec2_send_command.sh gt_server "bash -c 'cd gatekeeper; (sudo nohup ./build/gatekeeper -- -l grantor.log &>/dev/null) &'"
sleep 10

# Add forwarding rule to Gatekeeper server.
./ec2_send_file.sh gk1_server "tests/gk/config/add.lua" "gatekeeper/lua/examples/add.lua"
./ec2_send_command.sh gk1_server "cd gatekeeper; sudo ./gkctl/gkctl lua/examples/add.lua" >/dev/null

# Start HTTP server.
./ec2_send_command.sh dest "nohup bash -c 'python3 SimpleHTTPServerWithUpload.py' &>/dev/null &"

# Calibrate client.
#./ec2_send_command.sh client "nohup bash -c 'cd raw-packets; sudo make; sudo ./calibrateGk 0 ${EXP_RATE}'"

# Start capturing attacker TX rate and server RX rate.
./ec2_send_command.sh client "nohup bash -c 'while true; do date >> /home/ubuntu/client_ifconfig.txt && ifconfig | grep ens5 --after-context=8 >> /home/ubuntu/client_ifconfig.txt && sleep 1; done' &>/dev/null &"
./ec2_send_command.sh dest "nohup bash -c 'while true;   do date >> /home/ubuntu/server_ifconfig.txt && ifconfig | grep ens3 --after-context=8 >> /home/ubuntu/server_ifconfig.txt && sleep 5; done' &>/dev/null &"

# Start attack traffic.
./ec2_send_command.sh client "nohup bash -c 'cd raw-packets; sudo make; sudo ./sendRawGk 0 ${EXP_RATE}' &>/dev/null &"

# Let attackers get up to speed.
sleep 20

# Start legitimate client.
./ec2_send_command.sh tcp "nohup bash -c 'sudo tcpdump -i ens5 not port 22 -w /home/ubuntu/legit_dump.pcap' &>/dev/null &"
./ec2_send_command.sh tcp "cd raw-packets/legit && ./send.sh"

echo "Cleaning up ..."

./ec2_reboot_instance.sh dest

./ec2_send_command.sh client "sudo pkill bash"		# ifconfig
./ec2_send_command.sh client "sudo pkill sendRawGk"
./ec2_get_file.sh client "/home/ubuntu/client_ifconfig.txt" results/${EXP_NAME}/${RESULTS_NAME}
./ec2_send_command.sh client "rm -rf /home/ubuntu/client_ifconfig.txt"

./ec2_send_command.sh tcp "sudo pkill nc"		# nc/tcp
./ec2_send_command.sh tcp "sudo pkill curl"		# http
./ec2_send_command.sh tcp "sudo pkill send.sh"
./ec2_send_command.sh tcp "sudo pkill tcpdump"
./ec2_send_command.sh tcp "sudo chmod ogu+r /home/ubuntu/raw-packets/legit/legit_log.txt"
./ec2_get_file.sh tcp "/home/ubuntu/raw-packets/legit/legit_log.txt" results/${EXP_NAME}/${RESULTS_NAME}
./ec2_send_command.sh tcp "sudo rm -rf /home/ubuntu/raw-packets/legit/legit_log.txt"
./ec2_get_file.sh tcp "/home/ubuntu/legit_dump.pcap" results/${EXP_NAME}/${RESULTS_NAME}
./ec2_send_command.sh tcp "rm -rf /home/ubuntu/legit_dump.pcap"

./ec2_send_command.sh gt_server "sudo pkill gatekeeper"
./ec2_send_command.sh gt_server "sudo chmod ogu+r /home/ubuntu/gatekeeper/grantor.log"
./ec2_get_file.sh gt_server "/home/ubuntu/gatekeeper/grantor.log" results/${EXP_NAME}/${RESULTS_NAME}
./ec2_send_command.sh gt_server "sudo rm -rf /home/ubuntu/gatekeeper/grantor.log"

./ec2_send_command.sh gk1_server "sudo pkill gatekeeper"
./ec2_send_command.sh gk1_server "sudo chmod ogu+r /home/ubuntu/gatekeeper/gatekeeper.log"
./ec2_get_file.sh gk1_server "/home/ubuntu/gatekeeper/gatekeeper.log" results/${EXP_NAME}/${RESULTS_NAME}
./ec2_send_command.sh gk1_server "sudo rm -rf /home/ubuntu/gatekeeper/gatekeeper.log"

echo "Instance restarting ..."
sleep 60
# Once the instance has had enough time, collect the server log.
./ec2_get_file.sh dest "/home/ubuntu/server_ifconfig.txt" results/${EXP_NAME}/${RESULTS_NAME}
