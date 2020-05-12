#!/bin/bash

if [ $# -ne 2 ]; then
  echo "usage: ./run_test.sh num_bots experiment_length"
  echo "e.g.: ./run_test.sh patch1 10 1 8 300 1"
  exit
fi

NUM_BOTS=$1
EXP_LEN=$2

# Start Gatekeeper.
#cd ../gatekeeper
#mkdir -p $EXP_NAME
#sudo ./build/gatekeeper -- -l ${EXP_NAME}/gk_2.${TABLE_EXP}_${NUM_LCORES}lcore_${NUM_BOTS}bots_${TRIAL_NUM}.log &
#sleep 5

# Add FIB entry.
#sudo ./gkctl/gkctl lua/examples/add.lua
#sleep 5

#cd ../gk-test-files
#make clean
#make

# Start bots in background.
sudo pkill sendRawEth
for i in $(eval echo {1..$NUM_BOTS})
do
  sudo ./sendRawEth &
#  if [ $i -gt 10 ];
#  then
#    sudo ./sendRawEthRandom $((3 + $i)) &
#  else
#    sudo ./sendRawEthRandom $((40 - $i)) &
#  fi
done

# Get stats every second until the experiment ends.
for i in $(eval echo {1..$EXP_LEN})
do
  ifconfig | head -8 >> ${NUM_BOTS}_bots.txt
  sleep 1
done
ifconfig | head -8 >> ${NUM_BOTS}_bots.txt

sudo pkill sendRawEth
