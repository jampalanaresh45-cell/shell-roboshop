#! /bin/bash
AMI_ID="ami-09c813fb71547fc4f"
SG_ID="sg-0b27bdc41b21e4e6d" #Replace with sg id of your ec2 instance
ZONE_ID="Z002601621GCC3UL69CM8" #Replace with your hosted zone id
DOMAIN_NAME="daws86s.store" #Replace with your domain name
for instance in $@
do
    INSTANCE_ID=$(aws ec2 run-instances --image-id $AMI_ID --instance-type t3.micro --security-group-ids $SG_ID --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" --query 'Instances[0].InstanceId' --output text)

###Get Private IP address of the instance
    if [ $instance != "Frontend" ]; then
        IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PrivateIpAddress' --output text)
        RECORD_NAME="$instance.$DOMAIN_NAME" #mongo.daws86s.store
    else
        IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)
        RECORD_NAME="$DOMAIN_NAME" #daws86s.store
    fi

        echo "$instance: $IP"

    ###Create Route53 entry
    # Creates route 53 records based on env name

aws route53 change-resource-record-sets \
  --hosted-zone-id $ZONE_ID \
  --change-batch '
  {
    "Comment": "Updating record set"
    ,"Changes": [{
      "Action"              : "UPSERT"
      ,"ResourceRecordSet"  : {
        "Name"              : "'$RECORD_NAME'"
        ,"Type"             : "A"
        ,"TTL"              : 1
        ,"ResourceRecords"  : [{
            "Value"         : "'$IP'"
        }]
      }
    }]
  }
  '

done