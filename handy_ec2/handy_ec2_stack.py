from aws_cdk import (
    Stack,
    aws_ec2 as ec2,
    aws_autoscaling as autoscaling,
    aws_iam as iam
)
from constructs import Construct

try:
    from handy_ec2.settings import SG_PREFIX_LIST
except ImportError:
    SG_PREFIX_LIST = None

class HandyEc2Stack(Stack):

    def __init__(self, scope: Construct, construct_id: str, **kwargs) -> None:
        super().__init__(scope, construct_id, **kwargs)
        default_vpc = ec2.Vpc.from_lookup(self, "DefaultVpc", is_default=True)
        public_sg = ec2.SecurityGroup(self, "SecurityGroup",
            vpc=default_vpc,
            security_group_name="PublicHandyEC2",
            description="Managed by CDK HandyEc2Stack")
        if SG_PREFIX_LIST:
            peer = ec2.Peer.prefix_list(SG_PREFIX_LIST)
        else:
            peer = ec2.Peer.any_ipv4()
        public_sg.add_ingress_rule(peer, ec2.Port.tcp(22), "SSH")
        public_sg.add_ingress_rule(peer, ec2.Port.tcp(3389), "Remote Desktop")
        windows = ec2.WindowsImage(ec2.WindowsVersion.WINDOWS_SERVER_2022_CHINESE_SIMPLIFIED_FULL_BASE)
        instance_profile = iam.Role(self, "Role",
            assumed_by=iam.ServicePrincipal("ec2.amazonaws.com"),
            description="Instance Profile for HandyEc2Stack",
            role_name="HandyEc2Stack"
        )
        instance_profile.add_managed_policy(iam.ManagedPolicy.from_aws_managed_policy_name("AmazonSSMManagedEC2InstanceDefaultPolicy"))

        autoscaling.AutoScalingGroup(self, "ASG",
            auto_scaling_group_name="HandyEC2ASG",
            vpc=default_vpc,
            instance_type=ec2.InstanceType.of(ec2.InstanceClass.T3, ec2.InstanceSize.LARGE),
            machine_image=windows,
            security_group=public_sg,
            desired_capacity=1,
            min_capacity=1,
            max_capacity=1,
            key_name=f"{self.account}-{self.region}-ec2-keypair",
            role=instance_profile
        )
        
