#!/usr/bin/env python3
import os

import aws_cdk as cdk

from handy_ec2.handy_ec2_stack import HandyEc2Stack


app = cdk.App()
HandyEc2Stack(app, "HandyEc2Stack",
    env=cdk.Environment(account=os.getenv('CDK_DEFAULT_ACCOUNT'), region=os.getenv('CDK_DEFAULT_REGION'))
)

app.synth()
