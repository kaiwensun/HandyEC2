from aws_cdk import (
    # Duration,
    Stack,
    aws_ec2 as ec2,
    aws_autoscaling as autoscaling
    # aws_sqs as sqs,
)
from constructs import Construct

class HandyEc2Stack(Stack):

    def __init__(self, scope: Construct, construct_id: str, **kwargs) -> None:
        super().__init__(scope, construct_id, **kwargs)
        default_vpc = ec2.Vpc.from_lookup(self, "DefaultVpc", is_default=True)
        public_sg = ec2.SecurityGroup(self, "SecurityGroup",
            vpc=default_vpc,
            security_group_name="PublicHandyEC2",
            description="Managed by CDK HandyEc2Stack")
        public_sg.add_ingress_rule(ec2.Peer.any_ipv4(), ec2.Port.tcp(22), "SSH")
        public_sg.add_ingress_rule(ec2.Peer.any_ipv4(), ec2.Port.tcp(3389), "Remote Desktop")
        windows = ec2.WindowsImage(ec2.WindowsVersion.WINDOWS_SERVER_2022_CHINESE_SIMPLIFIED_FULL_BASE)
        autoscaling.AutoScalingGroup(self, "ASG",
            auto_scaling_group_name="HandyEC2ASG",
            vpc=default_vpc,
            instance_type=ec2.InstanceType.of(ec2.InstanceClass.M5, ec2.InstanceSize.LARGE),
            machine_image=windows,
            security_group=public_sg,
            desired_capacity=1,
            min_capacity=1,
            max_capacity=1,
            key_name=f"{self.account}-{self.region}-ec2-keypair"
        )
        
