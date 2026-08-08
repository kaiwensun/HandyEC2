import aws_cdk as core
import aws_cdk.assertions as assertions

from handy_ec2.windows_ec2_stack import WindowsEc2Stack
from handy_ec2.linux_ec2_stack import LinuxEc2Stack

TEST_ENV = core.Environment(account="123456789012", region="us-west-2")


def test_windows_stack_creates_asg():
    app = core.App()
    stack = WindowsEc2Stack(app, "windows-ec2", env=TEST_ENV)
    template = assertions.Template.from_stack(stack)
    template.resource_count_is("AWS::AutoScaling::AutoScalingGroup", 1)


def test_linux_stack_creates_asg():
    app = core.App()
    stack = LinuxEc2Stack(app, "linux-ec2", env=TEST_ENV)
    template = assertions.Template.from_stack(stack)
    template.resource_count_is("AWS::AutoScaling::AutoScalingGroup", 1)
