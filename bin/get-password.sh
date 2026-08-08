#!/bin/zsh

instance_id=`aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names WindowsEC2ASG --query "AutoScalingGroups[0].Instances[0].InstanceId" --output text`
password=`aws secretsmanager get-secret-value --secret-id "WindowsEc2Stack/WindowsAdministratorPassword" --query SecretString --output text`

public_dns=`aws ec2 describe-instances --instance-id $instance_id --query 'Reservations[0].Instances[0].PublicDnsName' --output text`

echo "Password: ${password}"
echo "DNS: ${public_dns}"
