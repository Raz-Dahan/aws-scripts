#!/bin/bash

AWS_REGION="eu-central-1"

delete_tags() {
  instance_id=$1
  aws ec2 delete-tags --region $AWS_REGION --resources $instance_id --tags Key=Name Key=platform
}

terminate_instance() {
  instance_id=$1
  aws ec2 terminate-instances --region $AWS_REGION --instance-ids $instance_id
}

prod_instances=$(aws ec2 describe-instances --region $AWS_REGION --filters "Name=tag:Name,Values=Prod" "Name=tag:platform,Values=production" --query "Reservations[*].Instances[*].InstanceId" --output text)
dev_instances=$(aws ec2 describe-instances --region $AWS_REGION --filters "Name=tag:Name,Values=Dev" "Name=tag:platform,Values=test" --query "Reservations[*].Instances[*].InstanceId" --output text)

for instance_id in $prod_instances $dev_instances; do
  delete_tags $instance_id &> /dev/null
  terminate_instance $instance_id &> /dev/null
  echo "Terminated instance $instance_id"
done


echo '{
  "MaxCount": 1,
  "MinCount": 1,
  "ImageId": "ami-0b2ac948e23c57071",
  "InstanceType": "t2.micro",
  "KeyName": "raz-key",
  "EbsOptimized": false,
  "NetworkInterfaces": [
    {
      "AssociatePublicIpAddress": true,
      "DeviceIndex": 0,
      "Groups": [
        "sg-06fe143a3a8ada778"
      ]
    }
  ],
  "TagSpecifications": [
    {
      "ResourceType": "instance",
      "Tags": [
        {
          "Key": "Name",
          "Value": "Prod"
        },
        {
          "Key": "platform",
          "Value": "production"
        }
      ]
    }
  ],
  "IamInstanceProfile": {
    "Arn": "arn:aws:iam::820997886839:instance-profile/S3+EC2-Access"
  },
  "PrivateDnsNameOptions": {
    "HostnameType": "ip-name",
    "EnableResourceNameDnsARecord": true,
    "EnableResourceNameDnsAAAARecord": false
  }
}' > config.json

aws ec2 run-instances --region $AWS_REGION --cli-input-json file://config.json &> /dev/null


echo '{
  "MaxCount": 1,
  "MinCount": 1,
  "ImageId": "ami-0b2ac948e23c57071",
  "InstanceType": "t2.micro",
  "KeyName": "raz-key",
  "EbsOptimized": false,
  "NetworkInterfaces": [
    {
      "AssociatePublicIpAddress": true,
      "DeviceIndex": 0,
      "Groups": [
        "sg-06fe143a3a8ada778"
      ]
    }
  ],
  "TagSpecifications": [
    {
      "ResourceType": "instance",
      "Tags": [
        {
          "Key": "Name",
          "Value": "Dev"
        },
        {
          "Key": "platform",
          "Value": "test"
        }
      ]
    }
  ],
  "IamInstanceProfile": {
    "Arn": "arn:aws:iam::820997886839:instance-profile/S3+EC2-Access"
  },
  "PrivateDnsNameOptions": {
    "HostnameType": "ip-name",
    "EnableResourceNameDnsARecord": true,
    "EnableResourceNameDnsAAAARecord": false
  }
}' > config.json

aws ec2 run-instances --region $AWS_REGION --cli-input-json file://config.json &> /dev/null

echo 'New "Prod" and "Dev" instances are running'
