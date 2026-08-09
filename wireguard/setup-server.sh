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

apt-get update -qq
apt-get install -y -qq wireguard qrencode

WG_DIR=/etc/wireguard
CONF="${WG_DIR}/wg0.conf"
LISTEN_PORT=51820

if [[ ! -f "${CONF}" ]]; then
    umask 077
    [[ -f "${WG_DIR}/privatekey" ]] || wg genkey > "${WG_DIR}/privatekey"
    wg pubkey < "${WG_DIR}/privatekey" > "${WG_DIR}/publickey"
    egress_if=`ip route show default | awk '{print $5; exit}'`
    server_private_key=`cat "${WG_DIR}/privatekey"`
    cat > "${CONF}" <<EOF
[Interface]
Address = 10.8.0.1/24
ListenPort = ${LISTEN_PORT}
PrivateKey = ${server_private_key}
PostUp = iptables -C FORWARD -i wg0 -j ACCEPT 2>/dev/null || iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -C POSTROUTING -s 10.8.0.0/24 -o ${egress_if} -j MASQUERADE 2>/dev/null || iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o ${egress_if} -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT 2>/dev/null || true; iptables -t nat -D POSTROUTING -s 10.8.0.0/24 -o ${egress_if} -j MASQUERADE 2>/dev/null || true
EOF
    chmod 600 "${CONF}"
    echo "Created ${CONF}"
else
    echo "${CONF} already exists, leaving it (and any existing peers) untouched"
fi

echo 'net.ipv4.ip_forward=1' > /etc/sysctl.d/99-wireguard.conf
sysctl -p /etc/sysctl.d/99-wireguard.conf > /dev/null

if ufw status | grep -q "Status: active"; then
    ufw allow "${LISTEN_PORT}/udp" > /dev/null
fi

systemctl enable wg-quick@wg0 > /dev/null
systemctl is-active --quiet wg-quick@wg0 || systemctl start wg-quick@wg0
wg show wg0
REMOTE_SCRIPT
