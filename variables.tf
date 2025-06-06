variable "name" {
  description = "Name prefix for the created AWS resources (e.g., ASG, Launch Template, IAM Role, Security Group)."
  type        = string
}

variable "cluster_name" {
  description = "Identifier for the cluster or environment, used in resource naming and tags (e.g., 'dev', 'prod')."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the agent instances and related resources will be created."
  type        = string
}

variable "instances_subnet_ids" {
  description = "List of private subnet IDs where the EC2 agent instances will be launched."
  type        = list(string)
}

variable "azuredevops_url" {
  description = "Azure DevOps organization URL (e.g., https://dev.azure.com/your-organization)."
  type        = string

  validation {
    condition     = can(regex("^https://dev\\.azure\\.com/", var.azuredevops_url)) || can(regex("^https://.*\\.visualstudio\\.com", var.azuredevops_url))
    error_message = "The azuredevops_url must start with 'https://dev.azure.com/' or be a valid classic Azure DevOps URL (https://org.visualstudio.com)."
  }
}

variable "azuredevops_token" {
  description = "Azure DevOps Personal Access Token (PAT) with 'Agent Pools (Read & manage)' scope for agent registration."
  type        = string
  sensitive   = true
}

variable "azuredevops_pool" {
  description = "Azure DevOps agent pool name where the agents will be registered."
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for the agents (must be compatible with x64 architecture)."
  type        = string
  default     = "t3.micro" 
}

variable "al2_ami_ssm_parameter_name" {
  description = "value of the SSM parameter name for the latest Amazon Linux 2 AMI ID."
  type        = string
  default     = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

variable "ebs_volume_size" {
  description = "Size in GB for the root EBS volume of the agent instances."
  type        = number
  default     = 32

  validation {
    condition     = var.ebs_volume_size > 0
    error_message = "EBS volume size must be greater than 0."
  }
}

variable "ebs_volume_type" {
  description = "Type of EBS volume for the agent instances. Common types are 'gp2', 'gp3', 'io1', 'io2', 'st1', 'sc1'."
  type        = string
  default     = "gp3"

  validation {
    condition     = contains(["gp2", "gp3", "io1", "io2", "st1", "sc1"], var.ebs_volume_type)
    error_message = "EBS volume type must be one of: gp2, gp3, io1, io2, st1, sc1."
  }
}
variable "ebs_volume_iops" {
  description = "IOPS for the EBS volume. Required for 'io1' and 'io2' types."
  type        = number
  default     = 3000

  validation {
    condition     = var.ebs_volume_iops >= 0
    error_message = "EBS volume IOPS must be non-negative."
  }
}
variable "asg_max_size" {
  description = "Maximum number of instances in the Auto Scaling Group."
  type        = number
  default     = 1

  validation {
    condition     = var.asg_max_size >= 0
    error_message = "Maximum ASG size must be non-negative."
  }
}

variable "asg_min_size" {
  description = "Minimum number of instances in the Auto Scaling Group."
  type        = number
  default     = 1

  validation {
    condition     = var.asg_min_size >= 0
    error_message = "Minimum ASG size must be non-negative."
  }
}

variable "asg_desired_size" {
  description = "Desired number of instances in the Auto Scaling Group."
  type        = number
  default     = 1

  validation {
    condition     = var.asg_desired_size >= var.asg_min_size && var.asg_desired_size <= var.asg_max_size
    error_message = "Desired ASG size must be between min and max size, inclusive."
  }
}

variable "dotnet_sdk_version" {
  description = "Full .NET SDK version to be pre-installed into the agents (e.g., '6.0'). Check Microsoft docs for available versions."
  type        = string
  default     = "6.0"
}

variable "install_dotnet_sdk" {
  description = "Whether to install the .NET SDK on the agent instances. If false, .NET will not be installed."
  type        = bool
  default     = true
}

variable "install_docker" {
  description = "Whether to install Docker on the agent instances. If false, Docker will not be installed."
  type        = bool
  default     = false
}

variable "docker_user_groups" {
  description = "List of users to add to the docker group. Default is ['ec2-user']."
  type        = list(string)
  default     = ["ec2-user"]
}

variable "docker_restart_instance" {
  description = "Whether to restart the instance after Docker installation to ensure group membership changes take effect. Only used when install_docker is true."
  type        = bool
  default     = false
}

variable "docker_security_acknowledgment" {
  description = "Set to 'I understand the security implications' to acknowledge that users in the docker group effectively have root privileges."
  type        = string
  default     = null

  validation {
    condition     = !var.install_docker || var.docker_security_acknowledgment == "I understand the security implications"
    error_message = "When enabling Docker, you must set docker_security_acknowledgment to 'I understand the security implications' to acknowledge security implications."
  }
}

variable "metadata_http_put_response_hop_limit" {
  description = "The desired HTTP PUT response hop limit for instance metadata requests. The larger the number, the further instance metadata requests can travel. Default is 1 (most secure). For Docker containers to access instance metadata, a minimum of 2 is required. For docker-in-docker scenarios, 3 or higher might be needed."
  type        = number
  default     = 1
}

variable "azure_devops_agent_version" {
  description = "Version of the Azure DevOps agent to install (e.g., '4.254.0'). Find versions at https://github.com/microsoft/azure-pipelines-agent/releases"
  type        = string
  default     = "4.254.0"

  validation {
    condition     = can(regex("^\\d+\\.\\d+\\.\\d+$", var.azure_devops_agent_version))
    error_message = "Agent version must be in the format X.Y.Z."
  }
}

variable "attach_security_group_ids" {
  description = "List of additional Security Group IDs to attach to the agent instances."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "A map of additional tags to assign to the created resources."
  type        = map(string)
  default     = {}
}

variable "enable_ssh_access" {
  description = "Whether to enable SSH access to the agent instances."
  type        = bool
  default     = false
}

variable "ssh_cidr_blocks" {
  description = "List of CIDR blocks allowed to SSH into the agent instances. Only used when enable_ssh_access is true."
  type        = list(string)
  default     = []
  
  validation {
    condition     = !var.enable_ssh_access || length(var.ssh_cidr_blocks) > 0
    error_message = "When enable_ssh_access is true, ssh_cidr_blocks must contain at least one CIDR block."
  }
}

variable "ssh_key_name" {
  description = "Name of an existing SSH key pair to use for the agent instances. If not provided and enable_ssh_access is true, a new key pair will be generated."
  type        = string
  default     = null
}

variable "generate_ssh_key" {
  description = "Whether to generate a new SSH key pair for the agent instances. Only used when enable_ssh_access is true and ssh_key_name is not provided."
  type        = bool
  default     = true
}
