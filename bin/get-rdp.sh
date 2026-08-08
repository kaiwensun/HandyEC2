#!/bin/zsh

output_path="${1:-${HOME}/Downloads/HandyEC2.rdp}"

instance_id=`aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names HandyEC2ASG --query "AutoScalingGroups[0].Instances[0].InstanceId" --output text`
public_dns=`aws ec2 describe-instances --instance-id "${instance_id}" --query 'Reservations[0].Instances[0].PublicDnsName' --output text`

cat > "${output_path}" <<EOF
full address:s:${public_dns}
username:s:Administrator
prompt for credentials:i:1
EOF

echo "RDP file written to: ${output_path}"
echo "DNS: ${public_dns}"
