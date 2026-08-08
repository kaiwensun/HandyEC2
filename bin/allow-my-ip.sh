#!/bin/zsh

rule_description="allow-my-ip.sh"

target="${1}"
case "${target}" in
    windows)
        sg_name="PublicWindowsEC2"
        ports=(22 3389)
        ;;
    linux)
        sg_name="PublicLinuxEC2"
        ports=(22)
        ;;
    *)
        echo "Usage: $0 <windows|linux> [ip|--clean]"
        exit 1
        ;;
esac
shift

sg_id=`aws ec2 describe-security-groups --filters "Name=group-name,Values=${sg_name}" --query "SecurityGroups[0].GroupId" --output text`
if [[ -z "${sg_id}" || "${sg_id}" == "None" ]]; then
    echo "Security group ${sg_name} not found"
    exit 1
fi

if [[ "${1}" == "--clean" ]]; then
    aws ec2 describe-security-groups --group-ids "${sg_id}" \
        --query "SecurityGroups[0].IpPermissions[]" --output json | \
        jq -c --arg desc "${rule_description}" \
        '.[] | {IpProtocol, FromPort, ToPort, IpRanges: [.IpRanges[] | select(.Description == $desc)]} | select(.IpRanges | length > 0)' | \
    while IFS= read -r permission; do
        aws ec2 revoke-security-group-ingress --group-id "${sg_id}" --ip-permissions "${permission}"
        cidr=`echo "${permission}" | jq -r '.IpRanges[0].CidrIp'`
        echo "Revoked ${cidr} on ${sg_id}"
    done
    exit 0
fi

target_ip="${1}"
if [[ -z "${target_ip}" ]]; then
    target_ip=`curl -s https://checkip.amazonaws.com`
    if [[ -z "${target_ip}" ]]; then
        echo "Failed to determine current public IP"
        exit 1
    fi
fi
cidr="${target_ip}/32"

for port in "${ports[@]}"; do
    aws ec2 authorize-security-group-ingress \
        --group-id "${sg_id}" \
        --ip-permissions "IpProtocol=tcp,FromPort=${port},ToPort=${port},IpRanges=[{CidrIp=${cidr},Description=${rule_description}}]" \
        2>&1 | grep -v "InvalidPermission.Duplicate"
done

echo "Allowed ${cidr} on ${sg_id} (ports ${ports[*]})"
