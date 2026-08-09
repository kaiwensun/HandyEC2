#!/bin/zsh

instance_id=`aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names LinuxEC2ASG --query "AutoScalingGroups[0].Instances[0].InstanceId" --output text`
public_dns=`aws ec2 describe-instances --instance-id "${instance_id}" --query 'Reservations[0].Instances[0].PublicDnsName' --output text`
region=`aws configure get region`
account_id=`aws sts get-caller-identity --query Account --output text`
key_path="${HOME}/.ssh/${account_id}-${region}-ec2-keypair.pem"

if [[ ! -f "${key_path}" ]]; then
    echo "SSH key not found: ${key_path}"
    exit 1
fi

ssh -i "${key_path}" -o StrictHostKeyChecking=accept-new "ubuntu@${public_dns}" sudo bash -s <<'REMOTE_SCRIPT'
set -e

systemctl disable --now wg-quick@wg0
echo "wg-quick@wg0 stopped and disabled. Existing peer config in /etc/wireguard/wg0.conf is left untouched."
REMOTE_SCRIPT
