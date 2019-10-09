#!/bin/bash

EXP_NAME=$1
EXP_OUTPUT=../gk-test-files/$1
NUM_BOTS=16

cd ../gatekeeper

# Save original files.
if [ ! -f "lua/gk.lua.bak" ]; then
  cp lua/gk.lua lua/gk.lua.bak
fi
if [ ! -f "lua/main_config.lua.bak" ]; then
  cp lua/main_config.lua lua/main_config.lua.bak
fi

# Output Markdown file header to output file.
echo "| lcores | table size | GK Mpps rcvd (0%) | GK Mpps rcvd (50%) | GK Mpps rcvd (99%) | GK Mpps rcvd (mean) | cli Mpps sent (0%) | cli Mpps sent (50%) | cli Mpps sent (99%) | cli Mpps sent (mean) |" > ${EXP_OUTPUT}.log
echo "|--------|------------|-------------------|--------------------|--------------------|---------------------|--------------------|---------------------|---------------------|----------------------|" >> ${EXP_OUTPUT}.log

# Loop over lcores.
for i in 1 2 3
do
  # Loop over table sizes.
  for j in 15 20 22
  do
    # Move temporary files into place and overwrite parameters as needed.
    cp lua/gk.lua.bak lua/gk.lua
    cp lua/main_config.lua.bak lua/main_config.lua
    sed -i "s/flow_ht_size = 1024/flow_ht_size = 2^$j/g" lua/gk.lua
    sed -i "s/n_lcores = 2/n_lcores = $i/g" lua/main_config.lua

    # Run experiment.
    pushd .
    cd ../gk-test-files
    sudo ./run_test.sh ${EXP_NAME} ${j} ${i} ${NUM_BOTS} 300 1

    # Collect statistics.
    stats=$(sudo python3 process_gk_stats.py ../gatekeeper/${EXP_NAME}/gk_2.${j}_${i}lcore_${NUM_BOTS}bots_1.log ../gatekeeper/${EXP_NAME}/stats_2.${j}_${i}lcore_${NUM_BOTS}bots_1.txt)
    gk_mpps_0=$(echo ${stats} | awk '{ print $1 }')
    gk_mpps_50=$(echo ${stats} | awk '{ print $2 }')
    gk_mpps_99=$(echo ${stats} | awk '{ print $3 }')
    gk_mpps_mean=$(echo ${stats} | awk '{ print $4 }')

    cli_mpps_0=$(echo ${stats} | awk '{ print $1 }')
    cli_mpps_50=$(echo ${stats} | awk '{ print $2 }')
    cli_mpps_99=$(echo ${stats} | awk '{ print $3 }')
    cli_mpps_mean=$(echo ${stats} | awk '{ print $4 }')

    popd

    # Output statistics for this experiment.
    echo "|  ${i}  |  2^${j}  |       ${gk_mpps_0}        |        ${gk_mpps_50}        |        ${gk_mpps_99}        |        ${gk_mpps_mean}         |       ${cli_mpps_0}        |        ${cli_mpps_50}        |        ${cli_mpps_99}        |         ${cli_mpps_mean}         | " >> ${EXP_OUTPUT}.log
    sleep 5
  done
  echo "|        |            |                   |                    |                    |                     |                    |                     |                     |                      |" >> ${EXP_OUTPUT}.log
  echo "|--------|------------|-------------------|--------------------|--------------------|---------------------|--------------------|---------------------|---------------------|----------------------|" >> ${EXP_OUTPUT}.log
done

cd ../gk-test-files
