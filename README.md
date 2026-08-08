
# Welcome to your CDK Python project!

This is a blank project for CDK development with Python.

The `cdk.json` file tells the CDK Toolkit how to execute your app.

This project is set up like a standard Python project.  The initialization
process also creates a virtualenv within this project, stored under the `.venv`
directory.  To create the virtualenv it assumes that there is a `python3`
(or `python` for Windows) executable in your path with access to the `venv`
package. If for any reason the automatic creation of the virtualenv fails,
you can create the virtualenv manually.

To manually create a virtualenv on MacOS and Linux:

```
$ python3 -m venv .venv
```

After the init process completes and the virtualenv is created, you can use the following
step to activate your virtualenv.

```
$ source .venv/bin/activate
```

If you are a Windows platform, you would activate the virtualenv like this:

```
% .venv\Scripts\activate.bat
```

Once the virtualenv is activated, you can install the required dependencies.

```
$ pip install -r requirements.txt
```

At this point you can now synthesize the CloudFormation template for this code.

```
$ cdk synth
```

To add additional dependencies, for example other CDK libraries, just add
them to your `setup.py` file and rerun the `pip install -r requirements.txt`
command.

## Useful commands

 * `cdk ls`                      list all stacks in the app (`WindowsEc2Stack`, `LinuxEc2Stack`)
 * `cdk synth`                   emits the synthesized CloudFormation template for all stacks
 * `cdk deploy WindowsEc2Stack`  deploy only the Windows EC2 stack
 * `cdk deploy LinuxEc2Stack`    deploy only the Linux (Ubuntu) EC2 stack
 * `cdk deploy --all`            deploy both stacks
 * `cdk destroy <stack>`         tear down a stack you no longer need
 * `cdk diff`                    compare deployed stacks with current state
 * `cdk docs`                    open CDK documentation

## Scripts

 * `bin/export-profile.sh <profile>` — export AWS credentials from an AWS CLI profile into the current shell
 * `bin/get-password.sh` — print the Windows Administrator password and public DNS of the running Windows instance
 * `bin/set-password.sh` — prompt for a new password, update it, and apply it to the running Windows instance immediately
 * `bin/get-rdp.sh [output-path]` — write an `.rdp` file for the running Windows instance (default: `~/Downloads/WindowsEC2.rdp`)
 * `bin/get-linux-info.sh` — print the public DNS and SSH command for the running Linux instance
 * `bin/allow-my-ip.sh <windows|linux> [ip]` — allow an IP (default: your current public IP) to access that instance over SSH/RDP
 * `bin/allow-my-ip.sh <windows|linux> --clean` — revoke all IPs previously allowed by `allow-my-ip.sh` for that stack

Enjoy!
