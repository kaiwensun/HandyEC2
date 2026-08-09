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

CONF=/etc/wireguard/wg0.conf
if [[ ! -f "${CONF}" ]]; then
    echo "wg0.conf not found. Run setup-server.sh first." >&2
    exit 1
fi

declare -A last_handshake
current_pubkey=""
while IFS= read -r line; do
    if [[ "${line}" == peer:* ]]; then
        current_pubkey="${line#peer: }"
    elif [[ "${line}" == *"latest handshake:"* ]]; then
        last_handshake["${current_pubkey}"]="${line#*latest handshake: }"
    fi
done < <(wg show wg0)

name=""
pubkey=""
allowed_ips=""
while IFS= read -r line; do
    if [[ "${line}" == "# peer: "* ]]; then
        name="${line#\# peer: }"
    elif [[ "${line}" == "PublicKey = "* ]]; then
        pubkey="${line#PublicKey = }"
    elif [[ "${line}" == "AllowedIPs = "* ]]; then
        allowed_ips="${line#AllowedIPs = }"
        handshake="${last_handshake[${pubkey}]:-never connected}"
        printf "%-16s %-16s %s\n" "${name}" "${allowed_ips}" "${handshake}"
        name=""
        pubkey=""
        allowed_ips=""
    fi
done < "${CONF}"
REMOTE_SCRIPT
