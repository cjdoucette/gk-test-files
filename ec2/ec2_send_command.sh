#!/bin/bash

key_name="gatekeeper.pem"

if [ "$#" -ne 2 ]; then
    echo "You must enter an instance name and a command"
    exit
fi

id=$(sudo aws ec2 describe-instances \
    --filters Name=tag:Name,Values=$1 Name=instance-state-name,Values=running \
    --output text \
    --query 'Reservations[*].Instances[*].InstanceId')

if [ -z ${id} ]; then
    echo "Instance $1 not found"
fi

ip_addr=$(sudo aws ec2 describe-instances \
    --instance-ids ${id} \
    --query 'Reservations[*].Instances[*].PublicIpAddress' \
    --output text)

echo $2

ssh -i ${key_name} -o LogLevel=error \
    ubuntu@ec2-$(echo "$ip_addr" | tr . -).us-east-2.compute.amazonaws.com \
    "$2"
