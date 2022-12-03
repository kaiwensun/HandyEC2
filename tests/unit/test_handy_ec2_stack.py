import aws_cdk as core
import aws_cdk.assertions as assertions

from handy_ec2.handy_ec2_stack import HandyEc2Stack

# example tests. To run these tests, uncomment this file along with the example
# resource in handy_ec2/handy_ec2_stack.py
def test_sqs_queue_created():
    app = core.App()
    stack = HandyEc2Stack(app, "handy-ec2")
    template = assertions.Template.from_stack(stack)

#     template.has_resource_properties("AWS::SQS::Queue", {
#         "VisibilityTimeout": 300
#     })
