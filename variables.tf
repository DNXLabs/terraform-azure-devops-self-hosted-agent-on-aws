variable "name" {
  description = "Name of this EC2 cluster"
}

variable "cluster_name" {
  description = "Environment name"
}

variable "vpc_id" {
  description = "VPC id for the instances"
  type        = string
}

variable "sg_cidr_blocks" {
  description = "List of cidr blocks for SSH access to the build agents"
  type        = list
  default     = [""]
}

variable "security_group_ids" {
  type        = list
  default     = []
  description = "Extra security groups for instances"
}

variable "instances_subnet" {
  type        = list
  description = "List of private subnet IDs for EC2 instances"
}

variable "azuredevops_url" {
  type        = string
  description = "Azure devops url for your organisation"
}

variable "azuredevops_token" {
  type        = string
  description = "Azure devops personal access token for agent registration"
}

variable "azuredevops_pool" {
  type        = string
  description = "Azure devops pool name for the agents"
}

variable "dotnet_sdk_version" {
  type        = string
  description = "Dotnet sdk version to be pre-installed into the agents"
  default     = "3.1"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type"
  default     = "t3.small"
}

variable "ebs_size" {
  type        = number
  description = "EBS size in GB for agent instances"
  default     = 32
}

variable "key_name" {
  type        = string
  description = "Key-Pair name for access into the agent instances"
}

variable "asg_max_size" {
  type        = number
  description = "Maximum size for ASG"
  default     = 1
}

variable "asg_min_size" {
  type        = number
  description = "Minimum size for ASG"
  default     = 1
}

variable "asg_desired_size" {
  type        = number
  description = "Desired size for ASG"
  default     = 1
}