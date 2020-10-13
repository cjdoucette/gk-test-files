#!/bin/bash

key_name="gatekeeper.pem"

id=$(sudo aws ec2 describe-instances \
  --filters Name=tag:Name,Values=${1} Name=instance-state-name,Values=running \
  --output text \
  --query 'Reservations[*].Instances[*].InstanceId')
sudo aws ec2 reboot-instances \
  --instance-ids ${id} \
sudo aws ec2 wait instance-running --instance-ids ${id}
