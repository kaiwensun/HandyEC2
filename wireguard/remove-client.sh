#!/bin/zsh

client_name="${1}"
if [[ -z "${client_name}" ]]; then
    echo "Usage: $0 <client-name>"
    exit 1
fi

instance_id=`aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names LinuxEC2ASG --query "AutoScalingGroups[0].Instances[0].InstanceId" --output text`
public_dns=`aws ec2 describe-instances --instance-id "${instance_id}" --query 'Reservations[0].Instances[0].PublicDnsName' --output text`
region=`aws configure get region`
account_id=`aws sts get-caller-identity --query Account --output text`
key_path="${HOME}/.ssh/${account_id}-${region}-ec2-keypair.pem"

if [[ ! -f "${key_path}" ]]; then
    echo "SSH key not found: ${key_path}"
    exit 1
fi

ssh -i "${key_path}" -o StrictHostKeyChecking=accept-new "ubuntu@${public_dns}" sudo bash -s -- "${client_name}" <<'REMOTE_SCRIPT'
set -e

client_name="${1}"
CONF=/etc/wireguard/wg0.conf

if [[ ! -f "${CONF}" ]]; then
    echo "wg0.conf not found. Run setup-server.sh first." >&2
    exit 1
fi

if ! grep -qx "# peer: ${client_name}" "${CONF}"; then
    echo "No peer named '${client_name}' found in ${CONF}" >&2
    exit 1
fi

sed -i "/^# peer: ${client_name}\$/,/^\$/d" "${CONF}"
wg syncconf wg0 <(wg-quick strip wg0)
echo "Removed peer '${client_name}'"
REMOTE_SCRIPT
