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
sudo pkill sendRawEth
for i in $(eval echo {1..$NUM_BOTS})
do
  if [ $i -gt 10 ];
  then
    sudo ./sendRawEthRandom $((6 + $i)) &
  else
    sudo ./sendRawEthRandom $((48 - $i)) &
  fi
done

# Get stats every second until the experiment ends.
for i in $(eval echo {1..$EXP_LEN})
do
  ifconfig | grep "ens1f1" --after-context=6 >> ../gatekeeper/${EXP_NAME}/stats_2.${TABLE_EXP}_${NUM_LCORES}lcore_${NUM_BOTS}bots_${TRIAL_NUM}.txt
  sleep 1
done
ifconfig | grep "ens1f1" --after-context=6 >> ../gatekeeper/${EXP_NAME}/stats_2.${TABLE_EXP}_${NUM_LCORES}lcore_${NUM_BOTS}bots_${TRIAL_NUM}.txt

sudo pkill sendRawEth
sudo pkill gatekeeper
