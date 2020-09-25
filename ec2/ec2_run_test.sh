#!/bin/bash

if [ $# -lt 1 ]; then
  echo "usage: ./ec2_run_test.sh test_name [OPTIONS]"
  echo "e.g.: ./ec2_run_test.sh iperf 1m 300 ipv6 tcp"
  exit
fi

TEST_NAME=$1
RESULTS_NAME=$1$(echo "${@:2}" | tr [:blank:] _)

# Create directory for experiment results.
mkdir -p results/${RESULTS_NAME}

#
# Cleanup any state from previous experiments.
#

echo "Cleaning up testbed from any previous tests ..."

./ec2_send_command.sh gt_server "sudo rm -rf /home/ubuntu/gatekeeper/grantor.log"
./ec2_send_command.sh gt_server "sudo pkill gatekeeper"

./ec2_send_command.sh gk1_server "sudo rm -rf /home/ubuntu/gatekeeper/gatekeeper.log"
./ec2_send_command.sh gk1_server "sudo pkill gatekeeper"

#
# Start Gatekeeper testbed.
#

# Initialize test environment.
echo "Initializing test" ${RESULTS_NAME} "..."
./tests/${TEST_NAME}/init.sh

# Run Gatekeeper and Grantor.
./ec2_send_command.sh gk1_server "bash -c 'cd gatekeeper; (sudo nohup ./build/gatekeeper -- -l gatekeeper.log &>/dev/null) &'"
./ec2_send_command.sh gt_server "bash -c 'cd gatekeeper; (sudo nohup ./build/gatekeeper -- -l grantor.log &>/dev/null) &'"

sleep 10

# Start test script.
echo "Starting test" ${RESULTS_NAME} "..."
./tests/${TEST_NAME}/run.sh "${@:2}"

#
# Clean up experiment and fetch logs.
#

echo "Cleaning up experiment..."

./ec2_send_command.sh gt_server "sudo pkill gatekeeper"
./ec2_send_command.sh gt_server "sudo chmod ogu+r /home/ubuntu/gatekeeper/grantor.log"
./ec2_get_file.sh gt_server "/home/ubuntu/gatekeeper/grantor.log" results/${RESULTS_NAME}
./ec2_send_command.sh gt_server "sudo rm -rf /home/ubuntu/gatekeeper/grantor.log"

./ec2_send_command.sh gk1_server "sudo pkill gatekeeper"
./ec2_send_command.sh gk1_server "sudo chmod ogu+r /home/ubuntu/gatekeeper/gatekeeper.log"
./ec2_get_file.sh gk1_server "/home/ubuntu/gatekeeper/gatekeeper.log" results/${RESULTS_NAME}
./ec2_send_command.sh gk1_server "sudo rm -rf /home/ubuntu/gatekeeper/gatekeeper.log"

#./ec2_send_command.sh gk1_server "cd gatekeeper; git reset --hard origin/gk_test"

echo "Done. See results/${RESULTS_NAME} for results."

# Uncomment to show statistics.
EXP_NAME=${TEST_NAME}$(echo "${@:2}" | tr [:blank:] _)
python3 process_gk_stats.py results/${EXP_NAME}/gatekeeper.log results/${EXP_NAME}/client_ifconfig.txt results/${EXP_NAME}/server_ifconfig.txt
