from aws_cdk import (
    Stack,
    CfnOutput,
    aws_ec2 as ec2,
    aws_autoscaling as autoscaling,
    aws_secretsmanager as secretsmanager
)
from constructs import Construct

from handy_ec2.common import create_public_security_group, create_ssm_instance_role


class WindowsEc2Stack(Stack):

    def __init__(self, scope: Construct, construct_id: str, **kwargs) -> None:
        super().__init__(scope, construct_id, **kwargs)
        default_vpc = ec2.Vpc.from_lookup(self, "DefaultVpc", is_default=True)
        public_sg = create_public_security_group(self, "SecurityGroup", default_vpc, "PublicWindowsEC2",
            [(22, "SSH"), (3389, "Remote Desktop")])
        windows = ec2.WindowsImage(ec2.WindowsVersion.WINDOWS_SERVER_2022_CHINESE_SIMPLIFIED_FULL_BASE)
        instance_profile = create_ssm_instance_role(self, "Role", "WindowsEc2Stack")

        windows_password_secret = secretsmanager.Secret(self, "WindowsPasswordSecret",
            secret_name=f"{construct_id}/WindowsAdministratorPassword",
            generate_secret_string=secretsmanager.SecretStringGenerator(
                password_length=32,
                exclude_characters="\"'`\\@/ "
            )
        )
        windows_password_secret.grant_read(instance_profile)

        set_password_commands = [
            f'$password = (Get-SECSecretValue -SecretId {windows_password_secret.secret_arn}).SecretString',
            '$secureString = ConvertTo-SecureString $password -AsPlainText -Force',
            'Get-LocalUser -Name "Administrator" | Set-LocalUser -Password $secureString'
        ]
        user_data = ec2.UserData.for_windows()
        user_data.add_commands(*set_password_commands)

        autoscaling.AutoScalingGroup(self, "ASG",
            auto_scaling_group_name="WindowsEC2ASG",
            vpc=default_vpc,
            instance_type=ec2.InstanceType.of(ec2.InstanceClass.T3, ec2.InstanceSize.LARGE),
            machine_image=windows,
            security_group=public_sg,
            desired_capacity=1,
            min_capacity=1,
            max_capacity=1,
            key_name=f"{self.account}-{self.region}-ec2-keypair",
            role=instance_profile,
            user_data=user_data
        )

        CfnOutput(self, "WindowsPasswordSecretArn", value=windows_password_secret.secret_arn)
