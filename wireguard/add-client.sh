#!/bin/zsh

client_name="${1}"
output_format="${2:-qr}"
if [[ -z "${client_name}" || ( "${output_format}" != "qr" && "${output_format}" != "--text" ) ]]; then
    echo "Usage: $0 <client-name> [--text]"
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

ssh -i "${key_path}" -o StrictHostKeyChecking=accept-new "ubuntu@${public_dns}" sudo bash -s -- "${client_name}" "${public_dns}" "${output_format}" <<'REMOTE_SCRIPT'
set -e

client_name="${1}"
public_dns="${2}"
output_format="${3}"
WG_DIR=/etc/wireguard
CONF="${WG_DIR}/wg0.conf"
LISTEN_PORT=51820

if [[ ! -f "${CONF}" ]]; then
    echo "wg0.conf not found. Run setup-server.sh first." >&2
    exit 1
fi

if grep -qx "# peer: ${client_name}" "${CONF}"; then
    echo "A peer named '${client_name}' already exists in ${CONF}" >&2
    exit 1
fi

peer_count=`grep -c '^\[Peer\]' "${CONF}" || true`
next_octet=$(( peer_count + 2 ))
client_ip="10.8.0.${next_octet}"

umask 077
client_private_key=`wg genkey`
client_public_key=`echo "${client_private_key}" | wg pubkey`
server_public_key=`cat "${WG_DIR}/publickey"`

cat >> "${CONF}" <<EOF

# peer: ${client_name}
[Peer]
PublicKey = ${client_public_key}
AllowedIPs = ${client_ip}/32
EOF

wg syncconf wg0 <(wg-quick strip wg0)

client_conf=$(cat <<EOF
[Interface]
PrivateKey = ${client_private_key}
Address = ${client_ip}/24
DNS = 1.1.1.1

[Peer]
PublicKey = ${server_public_key}
Endpoint = ${public_dns}:${LISTEN_PORT}
AllowedIPs = 0.0.0.0/0, ::/0
PersistentKeepalive = 25
EOF
)

if [[ "${output_format}" == "--text" ]]; then
    echo "${client_conf}"
else
    echo "${client_conf}" | qrencode -t ansiutf8
fi
unset client_private_key client_conf
REMOTE_SCRIPT
