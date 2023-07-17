#!/bin/bash

ACTION=$(echo $1 | sed -r 's/^.{2}//')
if [[ $ACTION != "start" ]] && [[ $ACTION != "stop" ]] && [[ $ACTION != "destroy" ]]; then
  echo "please give -- followed by strat/stop/destroy"
  exit 0
fi

if [[ $ACTION = "destroy" ]]; then
  ACTION=terminate
fi

echo "are you sure you want to $ACTION? (y/n)"
read ANSWER
while [[ $ANSWER != "y" ]] && [[ $ANSWER != "n" ]];
do
echo "please give y or n as answer"
  read ANSWER
done

if [[ $ANSWER = "n" ]]; then
  exit 0
fi

IDS=$(aws ec2 describe-instances --filters "Name=instance-type,Values=t2.micro" "Name=instance-state-name,Values=running,pending,stopping,stopped" --query "Reservations[].Instances[].InstanceId" --output text)
aws ec2 $ACTION-instances --instance-ids $IDS
