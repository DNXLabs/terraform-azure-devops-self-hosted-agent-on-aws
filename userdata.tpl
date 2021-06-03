#!/bin/bash
export VSTS_AGENT_INPUT_URL=${url}
export VSTS_AGENT_INPUT_AUTH=pat
export VSTS_AGENT_INPUT_TOKEN=${token}
export VSTS_AGENT_INPUT_POOL=${pool}

# install packages
yum update -y
yum install git tar -y
# install devops build agent
cd /home/ec2-user
mkdir azure_devops_build_agent && cd azure_devops_build_agent
curl https://vstsagentpackage.azureedge.net/agent/2.186.1/vsts-agent-linux-x64-2.186.1.tar.gz -O
chown -R ec2-user:ec2-user .

# configure devops build agent
tar zxvf vsts-agent-linux-x64-2.186.1.tar.gz
rm vsts-agent-linux-x64-2.186.1.tar.gz
chown -R ec2-user:ec2-user .

su ec2-user -c './config.sh --unattended'
# configure the devops build agent service and run it
./svc.sh install
./svc.sh start
su ec2-user -c 'mkdir -p _work'