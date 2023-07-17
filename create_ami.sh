#!/bin/bash

echo "What is your instance's name?"
read NAME

echo "#!/bin/bash
sudo yum update -y
sudo yum install git -y
sudo yum install python3-pip -y
git clone https://github.com/Raz-Dahan/flask-websites.git
cd flask-websites/alpaca-flask/
pip install -r requirements.txt
echo \"#!/bin/sh
cd /flask-websites/alpaca-flask/
flask run --host=0.0.0.0
exit 0\" > /etc/rc.d/rc.local
sudo chmod -v +x /etc/rc.d/rc.local
sudo systemctl enable rc-local.service
sudo systemctl start rc-local.service
" > user_data.sh
sudo chmod u+x user_data.sh

aws ec2 run-instances \
    --image-id ami-07151644aeb34558a \
    --count 1 \
    --instance-type t2.micro \
    --key-name raz-key \
    --security-group-ids sg-06fe143a3a8ada778 \
    --subnet-id subnet-0cbfec9bda9b77bd5 \
    --block-device-mappings "[{\"DeviceName\":\"/dev/sdf\",\"Ebs\":{\"VolumeSize\":8,\"DeleteOnTermination\":false}}]" \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$NAME}]" "ResourceType=volume,Tags=[{Key=Name,Value=$NAME-disk}]" \
    --user-data file:///home/cloudshell-user/user_data.sh &> /dev/null


ID=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=$NAME" --query "Reservations[].Instances[].InstanceId" | grep -oE '"[^"]+"' | sed 's/"//g')
STATUS=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=$NAME" --query "Reservations[].Instances[].State[].Name" | grep -oE '"[^"]+"' | sed 's/"//g')

echo "you created the instance $ID"
echo $STATUS

while true;
do
if [[ $STATUS = "pending" ]]; then
    sleep 5
    STATUS=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=$NAME" --query "Reservations[].Instances[].State[].Name" | grep -oE '"[^"]+"' | sed 's/"//g')
  fi
  if [[ $STATUS = "running" ]]; then
    echo "What is your new AMI name? (more than 3 chars)"
    read AMIname
    aws ec2 create-image --instance-id "$ID" --name "$AMIname" &> /dev/null
    echo "please wait 5 minutes"
    sleep 300
    echo "AMI created"
    echo "terminating instance"
    aws ec2 terminate-instances --instance-ids $ID &> /dev/null
    echo "done"
    exit 0
  fi
done