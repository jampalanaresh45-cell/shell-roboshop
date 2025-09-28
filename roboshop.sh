#! /bin/bash
AMI_ID="ami-09c813fb71547fc4f"
SG_ID="sg-0b27bdc41b21e4e6d" #Replace with sg id of your ec2 instance

for instance in $@
do
    INSTANCE_ID=$(aws ec2 run-instances --image-id $AMI_ID --instance-type t3.micro --security-group-ids $SG_ID --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" --query 'Instances[0].InstanceId' --output text)

###Get Private IP address of the instance
    if [ $instance != "Frontend" ]; then
        IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PrivateIpAddress' --output text)

    else
        IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)

    fi

        echo "$instance: $IP"

done