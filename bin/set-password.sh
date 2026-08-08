#!/bin/zsh

read -s "?New password: " new_password
echo
if [[ -z "${new_password}" ]]; then
    echo "Password must not be empty"
    exit 1
fi

secret_id="WindowsEc2Stack/WindowsAdministratorPassword"
instance_id=`aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names WindowsEC2ASG --query "AutoScalingGroups[0].Instances[0].InstanceId" --output text`

aws secretsmanager put-secret-value --secret-id "${secret_id}" --secret-string "${new_password}" > /dev/null

command_id=`aws ssm send-command \
    --instance-ids "${instance_id}" \
    --document-name "AWS-RunPowerShellScript" \
    --parameters "commands=[\"\$password = (Get-SECSecretValue -SecretId ${secret_id}).SecretString\",\"\$secureString = ConvertTo-SecureString \$password -AsPlainText -Force\",\"Get-LocalUser -Name 'Administrator' | Set-LocalUser -Password \$secureString\"]" \
    --query "Command.CommandId" --output text`

echo "Waiting for command ${command_id} to finish on ${instance_id}..."
aws ssm wait command-executed --command-id "${command_id}" --instance-id "${instance_id}"

status=`aws ssm get-command-invocation --command-id "${command_id}" --instance-id "${instance_id}" --query "Status" --output text`
echo "Command status: ${status}"
