#!/bin/bash
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
echo "Starting Azure DevOps agent setup script at $(date)"
set -e # Exit immediately if a command exits with a non-zero status.

# --- Variables Passed from Terraform ---
# These shell variables capture the values rendered by Terraform's templatefile function
AZP_URL="${azuredevops_url}"
AZP_TOKEN="${azuredevops_token}"
AZP_POOL="${azuredevops_pool}"
AZP_AGENT_VERSION="${azure_devops_agent_version}"
DOTNET_SDK_VERSION="${dotnet_sdk_version}"
CLUSTER_NAME="${cluster_name}"
AGENT_NAME_PREFIX="${name}"
# Note: Using the snake_case variable directly in the if condition below is preferred,
# but assigning it here doesn't hurt either.
INSTALL_DOTNET_SDK="${install_dotnet_sdk}"
# Fixed architecture to x64
TARGET_ARCHITECTURE="x64"

# --- Environment Setup ---
AZP_AGENT_FOLDER="/home/ec2-user/myagent"
AZP_USER="ec2-user"

# --- Install Prerequisites ---
echo "Installing prerequisites..."
sudo yum update -y
sudo yum install -y git tar libicu jq amazon-ec2-instance-selector

# --- .NET SDK Installation (optional) ---
# Use the snake_case variable directly from Terraform template rendering
if [ "${install_dotnet_sdk}" = "true" ]; then
  # Use the shell variables defined above for echo statements
  echo "Installing .NET SDK version $DOTNET_SDK_VERSION for $TARGET_ARCHITECTURE..."
  sudo rpm -Uvh https://packages.microsoft.com/config/centos/7/packages-microsoft-prod.rpm
  # Use the snake_case variable directly from Terraform for the package name
  sudo yum install -y dotnet-sdk-${dotnet_sdk_version}
  echo ".NET SDK Installation complete. Version: $(dotnet --version)"
else
  echo ".NET SDK installation skipped."
fi

# --- Docker Installation (optional) ---
if [ "${install_docker}" = "true" ]; then
  echo "Checking for Docker installation..."
  if command -v docker &> /dev/null; then
    echo "Docker is already installed. Version: $(docker --version)"
  else
    echo "Installing Docker..."
    sudo yum update -y
    sudo amazon-linux-extras install docker -y || { echo "Failed to install Docker"; exit 1; }
    sudo systemctl start docker || { echo "Failed to start Docker service"; exit 1; }
    sudo systemctl enable docker || { echo "Failed to enable Docker service"; exit 1; }
    echo "Docker installed successfully. Version: $(docker --version)"
  fi
  
  # Add specified users to the docker group
  for user in ${jsonencode(docker_user_groups)}; do
    # Remove quotes and brackets from the rendered JSON array
    clean_user=$(echo "$user" | sed 's/[][]//g' | sed 's/"//g' | sed 's/,//g')
    echo "Adding $clean_user to the docker group..."
    sudo usermod -aG docker $clean_user || { echo "Failed to add $clean_user to docker group"; exit 1; }
  done
  
  echo "Note: Users may need to log out and back in for group changes to take effect"
  
  # Optionally restart the instance to apply group changes
  if [ "${docker_restart_instance}" = "true" ]; then
    echo "Scheduling instance restart to apply Docker group membership changes..."
    # Schedule a reboot in 1 minute to allow the script to complete
    sudo shutdown -r +1 "Rebooting to apply Docker group membership changes"
  fi
else
  echo "Docker installation skipped."
fi

# Create agent directory
# Use the shell variable defined above
echo "Setting up Azure DevOps Agent ${azure_devops_agent_version} for $TARGET_ARCHITECTURE..."
# Use the new CDN URL and the shell variable defined above
AZP_AGENTPACKAGE_URL="https://download.agent.dev.azure.com/agent/${azure_devops_agent_version}/vsts-agent-linux-$TARGET_ARCHITECTURE-${azure_devops_agent_version}.tar.gz"

# Use the shell variable defined above
echo "Creating agent folder"
sudo mkdir -p $AZP_AGENT_FOLDER
cd $AZP_AGENT_FOLDER

# Use the shell variable defined above
echo "Downloading Azure DevOps Agent "
for i in 1 2 3; do
  echo "Download attempt $i..."
  # Use the shell variable defined above
  sudo curl -fsSL -o vsts-agent-linux.tar.gz "$AZP_AGENTPACKAGE_URL" && echo "Download successful." && break
  echo "Download attempt $i failed. Retrying in 5 seconds..."
  sleep 5
  if [ $i -eq 3 ]; then
    echo "FATAL: Failed to download agent after 3 attempts. Exiting."
    exit 1
  fi
done

echo "Extracting Azure DevOps Agent..."
sudo tar zxf vsts-agent-linux.tar.gz
sudo rm vsts-agent-linux.tar.gz

# Use the shell variables defined above
echo "Granting ownership of $AZP_AGENT_FOLDER to $AZP_USER"
sudo chown -R $AZP_USER:$AZP_USER $AZP_AGENT_FOLDER

# Get instance metadata for a more descriptive agent name
INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 15")" http://169.254.169.254/latest/meta-data/instance-id)
# Use the shell variables defined above
CONFIGURED_AGENT_NAME="$AGENT_NAME_PREFIX-$INSTANCE_ID-$TARGET_ARCHITECTURE"

# Use the shell variables defined above
echo "Running agent configuration as user $AZP_USER..."
sudo -u $AZP_USER ./config.sh --unattended \
  --agent "$CONFIGURED_AGENT_NAME" \
  --url "$AZP_URL" \
  --auth PAT \
  --token "$AZP_TOKEN" \
  --pool "$AZP_POOL" \
  --work "_work" \
  --replace \
  --acceptTeeEula

echo "Installing Azure DevOps Agent service..."
# Use the shell variable defined above
sudo ./svc.sh install $AZP_USER

echo "Starting Azure DevOps Agent service..."
sudo ./svc.sh start

# --- CloudWatch Agent Setup ---
echo "Installing CloudWatch Agent..."
sudo yum install -y amazon-cloudwatch-agent

echo "Configuring CloudWatch Agent..."
# Use the shell variables defined above
CW_LOG_GROUP_BASE="/azure-devops-agent/$CLUSTER_NAME/$AGENT_NAME_PREFIX"
sudo tee /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<EOF
{
  "agent": {
    "run_as_user": "root"
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "$AZP_AGENT_FOLDER/_diag/*.log",
            "log_group_name": "$CW_LOG_GROUP_BASE/agent-diagnostics",
            "log_stream_name": "{instance_id}",
            "timezone": "UTC"
          },
          {
            "file_path": "/var/log/user-data.log",
            "log_group_name": "$CW_LOG_GROUP_BASE/user-data",
            "log_stream_name": "{instance_id}",
            "timezone": "UTC"
          }
        ]
      }
    }
  },
  "metrics": {
    "metrics_collected": {
      "disk": {
        "measurement": ["used_percent"],
        "resources": ["/"]
      },
      "mem": {
        "measurement": ["used_percent"]
      }
    },
    "append_dimensions": {
      "AutoScalingGroupName": "$${aws:AutoScalingGroupName}",
      "ImageId": "$${aws:ImageId}",
      "InstanceId": "$${aws:InstanceId}",
      "InstanceType": "$${aws:InstanceType}"
    }
  }
}
EOF

echo "Starting CloudWatch Agent..."
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
# Ensure the service is enabled to start on boot as well
sudo systemctl enable amazon-cloudwatch-agent
sudo systemctl start amazon-cloudwatch-agent

echo "Setup completed successfully!"
