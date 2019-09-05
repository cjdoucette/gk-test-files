#!/bin/bash

EXP_NAME=$1
EXP_OUTPUT=../gk-test-files/$1

cd ../gatekeeper

# Save original files.
if [ ! -f "lua/gk.lua.bak" ]; then
  cp lua/gk.lua lua/gk.lua.bak
fi
if [ ! -f "lua/main_config.lua.bak" ]; then
  cp lua/main_config.lua lua/main_config.lua.bak
fi

# Output Markdown file header to output file.
echo "| lcores | table size | GK Mpps rcvd | GK Gibps rcvd | client Mpps sent | client Gibps sent |" > ${EXP_OUTPUT}.log
echo "|--------|------------|--------------|---------------|------------------|-------------------|" >> ${EXP_OUTPUT}.log

# Loop over lcores.
for i in 1 2 3
do
  # Loop over table sizes.
  for j in 10 15 20
  do
    # Move temporary files into place and overwrite parameters as needed.
    cp lua/gk.lua.bak lua/gk.lua
    cp lua/main_config.lua.bak lua/main_config.lua
    sed -i "s/flow_ht_size = 1024/flow_ht_size = 2^$j/g" lua/gk.lua
    sed -i "s/n_lcores = 2/n_lcores = $i/g" lua/main_config.lua

    # Run experiment.
    pushd .
    cd ../gk-test-files
    sudo ./run_test.sh ${EXP_NAME} ${j} ${i} 8 300 1

    # Collect GK statistics.
    gk_stats=$(sudo python3 process_gk_stats.py ../gatekeeper/${EXP_NAME}/gk_2.${j}_${i}lcore_8bots_1.log)
    gk_mpps=$(echo ${gk_stats} | awk '{ print $1 }')
    gk_gibps=$(echo ${gk_stats} | awk '{ print $2 }')

    popd
    # Collect client statistics.
    client_stats=$(sudo cat ${EXP_NAME}/stats_2.${j}_${i}lcore_8bots_1.txt | grep "TX packets" | awk 'NR > 1 { printf "%0.2f\t %0.2f\n", ($3 - prev1)/1000/1000/300, ($5 - prev2)*8/1024/1024/1024/300 } { prev1 = $3 } { prev2 = $5 }')
    client_mpps=$(echo ${client_stats} | awk '{ print $1 }')
    client_gibps=$(echo ${client_stats} | awk '{ print $2 }')

    # Output statistics for this experiment.
    echo "${i} | 2^${j} | ${gk_mpps} | ${gk_gibps} | ${client_mpps} | ${client_gibps} |" >> ${EXP_OUTPUT}.log
  done
  echo "|        |            |              |              |                  |                  |" >> ${EXP_OUTPUT}.log
done

cd ../gk-test-files
