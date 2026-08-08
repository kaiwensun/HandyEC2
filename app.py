#!/usr/bin/env python3
import os

import aws_cdk as cdk

from handy_ec2.windows_ec2_stack import WindowsEc2Stack
from handy_ec2.linux_ec2_stack import LinuxEc2Stack


app = cdk.App()
env = cdk.Environment(account=os.getenv('CDK_DEFAULT_ACCOUNT'), region=os.getenv('CDK_DEFAULT_REGION'))
WindowsEc2Stack(app, "WindowsEc2Stack", env=env)
LinuxEc2Stack(app, "LinuxEc2Stack", env=env)

app.synth()
