from aws_cdk import (
    Stack,
    aws_ec2 as ec2,
    aws_autoscaling as autoscaling
)
from constructs import Construct

from handy_ec2.common import create_public_security_group, create_ssm_instance_role

UBUNTU_22_04_AMI_SSM_PARAMETER = "/aws/service/canonical/ubuntu/server/22.04/stable/current/amd64/hvm/ebs-gp2/ami-id"


class LinuxEc2Stack(Stack):

    def __init__(self, scope: Construct, construct_id: str, **kwargs) -> None:
        super().__init__(scope, construct_id, **kwargs)
        default_vpc = ec2.Vpc.from_lookup(self, "DefaultVpc", is_default=True)
        public_sg = create_public_security_group(self, "SecurityGroup", default_vpc, "PublicLinuxEC2",
            [(22, "SSH")])
        ubuntu = ec2.MachineImage.from_ssm_parameter(UBUNTU_22_04_AMI_SSM_PARAMETER, os=ec2.OperatingSystemType.LINUX)
        instance_profile = create_ssm_instance_role(self, "Role", "LinuxEc2Stack")

        autoscaling.AutoScalingGroup(self, "ASG",
            auto_scaling_group_name="LinuxEC2ASG",
            vpc=default_vpc,
            instance_type=ec2.InstanceType.of(ec2.InstanceClass.T3, ec2.InstanceSize.LARGE),
            machine_image=ubuntu,
            security_group=public_sg,
            desired_capacity=1,
            min_capacity=1,
            max_capacity=1,
            key_name=f"{self.account}-{self.region}-ec2-keypair",
            role=instance_profile
        )
