#!/bin/bash

if [ $# -lt 1 ]; then
  echo "usage: ./ec2_run_test.sh test_name [OPTIONS]"
  echo "e.g.: ./ec2_run_test.sh iperf 1m 300 ipv6 tcp"
  exit
fi

TEST_NAME=$1
RESULTS_NAME=$(echo "${@:2}" | tr [:blank:] _)

# Create directory for experiment results.
mkdir -p results/${TEST_NAME}/${RESULTS_NAME}

#
# Cleanup any state from previous experiments.
#

echo "Cleaning up testbed from any previous tests..."

./ec2_send_command.sh gt_server "sudo rm -rf /home/ubuntu/gatekeeper/grantor.log"
./ec2_send_command.sh gt_server "sudo pkill gatekeeper"

./ec2_send_command.sh gk1_server "sudo rm -rf /home/ubuntu/gatekeeper/gatekeeper.log"
./ec2_send_command.sh gk1_server "sudo pkill gatekeeper"

#
# Start Gatekeeper testbed.
#

# Initialize test environment.
echo "Initializing test ${TEST_NAME}/${RESULTS_NAME}..."
./tests/${TEST_NAME}/init.sh "${@:1}"

# Start test script.
echo "Starting test ${TEST_NAME}/${RESULTS_NAME}..."
./tests/${TEST_NAME}/run.sh "${@:1}"

#
# Clean up experiment and fetch logs.
#

#./ec2_send_command.sh gk1_server "cd gatekeeper; git reset --hard origin/gk_test"

echo "Done. See results/${TEST_NAME}/${RESULTS_NAME} for results."

python3 process_gk_stats.py ${TEST_NAME}/${RESULTS_NAME} > results/${TEST_NAME}/${RESULTS_NAME}/output.txt
