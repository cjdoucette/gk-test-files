#!/bin/bash

key_name="gatekeeper.pem"

nodes=(client gk1_server gk2_server gt_server router nat_server dest)
fname="ip_addrs.txt"

rm -f ${fname}

for i in "${nodes[@]}"; do
  id=$(sudo aws ec2 describe-instances \
    --filters Name=tag:Name,Values=${i} Name=instance-state-name,Values=running \
    --output text \
    --query 'Reservations[*].Instances[*].InstanceId')
  ip_addr=$(sudo aws ec2 describe-instances \
    --instance-ids ${id} \
    --query 'Reservations[*].Instances[*].PublicIpAddress' \
    --output text)
  echo ${i} ${ip_addr} >> ${fname}
done
