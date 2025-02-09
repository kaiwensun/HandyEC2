#!/bin/zsh

cred_file_path="${1}"
if [[ -z "${cred_file_path}" ]]; then
    region=`aws configure get region`
    account_id=`aws sts get-caller-identity --query Account --output text`
    cred_file_path="${HOME}/.ssh/${account_id}-${region}-ec2-keypair.pem"
fi

if [[ ! -f "${cred_file_path}" ]]; then
    echo "File not found: ${cred_file_path}"
    exit 1
fi

instance_id=`aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names HandyEC2ASG --query "AutoScalingGroups[0].Instances[0].InstanceId" --output text`
password_data=`aws ec2 get-password-data --instance-id "${instance_id}" --output text --query PasswordData`
password=`echo "${password_data}" | base64 --decode | openssl pkeyutl -decrypt -inkey "${cred_file_path}"`

public_dns=`aws ec2 describe-instances --instance-id $instance_id --query 'Reservations[0].Instances[0].PublicDnsName' --output text`

echo "Password: ${password}"
echo "DNS: ${public_dns}"

