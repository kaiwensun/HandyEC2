from aws_cdk import (
    aws_ec2 as ec2,
    aws_iam as iam
)

from handy_ec2.settings import SG_REGIONAL_PREFIX_LIST


def create_public_security_group(scope, construct_id, vpc, security_group_name, ports):
    security_group = ec2.SecurityGroup(scope, construct_id,
        vpc=vpc,
        security_group_name=security_group_name,
        description=f"Managed by CDK {scope.stack_name}")
    sg_prefix_list = SG_REGIONAL_PREFIX_LIST[scope.region]
    peer = ec2.Peer.prefix_list(sg_prefix_list) if sg_prefix_list else ec2.Peer.any_ipv4()
    for port, description in ports:
        security_group.add_ingress_rule(peer, ec2.Port.tcp(port), description)
    return security_group


def create_ssm_instance_role(scope, construct_id, role_name):
    role = iam.Role(scope, construct_id,
        assumed_by=iam.ServicePrincipal("ec2.amazonaws.com"),
        description=f"Instance Profile for {scope.stack_name}",
        role_name=role_name
    )
    role.add_managed_policy(iam.ManagedPolicy.from_aws_managed_policy_name("AmazonSSMManagedEC2InstanceDefaultPolicy"))
    return role
