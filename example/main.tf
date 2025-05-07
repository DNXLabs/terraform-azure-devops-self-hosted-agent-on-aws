### This is an example of how to use the DNXLabs Azure DevOps Self-Hosted Agent on AWS module.

module "agent_provider" {
  source = "git::https://github.com/DNXLabs/terraform-azure-devops-self-hosted-agent-on-aws.git?ref=1.0.0" #TODO: Replace with the correct version or branch of the module
  
  #--------------------------------------------------------------
  # General Configuration
  #--------------------------------------------------------------
  cluster_name = "azure-devops-self-hosted-agent-on-aws"
  name         = "azure-devops"
  
  #--------------------------------------------------------------
  # Network Configuration
  #--------------------------------------------------------------
  vpc_id              = "vpc-XXXXXX"
  instances_subnet_ids = ["subnet-XXXXXXX", "subnet-XXXXXXX", "subnet-XXXXXXX"]
  
  #--------------------------------------------------------------
  # Azure DevOps Configuration
  #--------------------------------------------------------------
  azuredevops_url           = "https://dev.azure.com/XXXXXXXX"
  azuredevops_token         = var.azuredevops_token # Personal Access Token (PAT) for Azure DevOps passed as an environment variable
  azuredevops_pool          = "aws_hosted"
  azure_devops_agent_version = "4.254.0" # Version of the Azure DevOps agent to install
  
  #--------------------------------------------------------------
  # Instance Configuration 
  #--------------------------------------------------------------
  instance_type        = "t3.small" # Must be x64 compatible
  
  #--------------------------------------------------------------
  # Auto Scaling Group Configuration
  #--------------------------------------------------------------
  asg_max_size     = 1
  asg_min_size     = 1
  asg_desired_size = 1
  
  #--------------------------------------------------------------
  # Storage Configuration
  #--------------------------------------------------------------
  ebs_volume_size  = 32  # Size in GB for the root EBS volume
  ebs_volume_type  = "gp3" # EBS volume type (gp2, gp3, io1, io2, st1, sc1)
  ebs_volume_iops  = 3000 # IOPS for the EBS volume
  
  #--------------------------------------------------------------
  # Development Tools Configuration
  #--------------------------------------------------------------
  install_dotnet_sdk = false
  dotnet_sdk_version = "" # .NET SDK version to be pre-installed
  
  #--------------------------------------------------------------
  # Docker Configuration (Optional)
  #--------------------------------------------------------------
  # Uncomment and configure the following lines to enable Docker
  # install_docker = true
  # docker_user_groups = ["ec2-user"] # List of users to add to the docker group
  # docker_restart_instance = true # Whether to restart the instance after Docker installation
  # docker_security_acknowledgment = "I understand the security implications" # Required when install_docker is true
  # metadata_http_put_response_hop_limit = 2 # Set to 2 or higher when using Docker to allow containers to access instance metadata
  
  #--------------------------------------------------------------
  # Additional Configuration
  #--------------------------------------------------------------
  attach_security_group_ids = [] # List of additional Security Group IDs to attach
  tags = {
    Environment = "example"
  }

  #--------------------------------------------------------------
  # SSH Access Configuration (Optional)
  #--------------------------------------------------------------
  # Uncomment and configure the following lines to enable SSH access
  # enable_ssh_access = true
  # ssh_cidr_blocks   = ["10.0.0.0/16", "192.168.1.0/24"] # List of CIDR blocks allowed to SSH
  # ssh_key_name      = null # Set to an existing key pair name or leave as null to generate a new key
  # generate_ssh_key  = true # Whether to generate a new key pair if ssh_key_name is null

}

variable "azuredevops_token" {
  description = "Azure DevOps Personal Access Token (PAT) with 'Agent Pools (Read & manage)' scope for agent registration."
  type        = string
  sensitive   = true
}
