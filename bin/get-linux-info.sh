#!/bin/zsh

instance_id=`aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names LinuxEC2ASG --query "AutoScalingGroups[0].Instances[0].InstanceId" --output text`
public_dns=`aws ec2 describe-instances --instance-id "${instance_id}" --query 'Reservations[0].Instances[0].PublicDnsName' --output text`
region=`aws configure get region`
account_id=`aws sts get-caller-identity --query Account --output text`

echo "DNS: ${public_dns}"
echo "SSH: ssh -i ~/.ssh/${account_id}-${region}-ec2-keypair.pem ubuntu@${public_dns}"
