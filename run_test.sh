#!/bin/bash

if [ $# -ne 6 ]; then
  echo "usage: ./run_test.sh experiment_name table_exponent num_lcores num_bots experiment_length trial_num"
  echo "e.g.: ./run_test.sh patch1 10 1 8 300 1"
  exit
fi

EXP_NAME=$1
TABLE_EXP=$2
NUM_LCORES=$3
NUM_BOTS=$4
EXP_LEN=$5
TRIAL_NUM=$6

# Start Gatekeeper.
cd ../gatekeeper
mkdir -p $EXP_NAME
sudo ./build/gatekeeper -- -l ${EXP_NAME}/gk_2.${TABLE_EXP}_${NUM_LCORES}lcore_${NUM_BOTS}bots_${TRIAL_NUM}.log &
sleep 5

# Add FIB entry.
sudo ./gkctl/gkctl lua/examples/add.lua
sleep 5

cd ../gk-test-files
make clean
make

# Start bots in background.
for i in {1..${NUM_BOTS}}
do
  sudo ./sendRawEthRandom &
done

# Get stats, wait, end experiment.
ifconfig | head -8 > ../gatekeeper/${EXP_NAME}/stats_2.${TABLE_EXP}_${NUM_LCORES}lcore_${NUM_BOTS}bots_${TRIAL_NUM}.txt
sleep ${EXP_LEN}
sudo pkill sendRawEth
ifconfig | head -8 >> ../gatekeeper/${EXP_NAME}/stats_2.${TABLE_EXP}_${NUM_LCORES}lcore_${NUM_BOTS}bots_${TRIAL_NUM}.txt

sudo pkill gatekeeper
