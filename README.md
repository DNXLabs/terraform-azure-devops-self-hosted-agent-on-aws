# terraform-azure-devops-self-hosted-agent-on-aws

[![Lint Status](https://github.com/DNXLabs/terraform-aws-template/workflows/Lint/badge.svg)](https://github.com/DNXLabs/terraform-aws-template/actions)
[![LICENSE](https://img.shields.io/github/license/DNXLabs/terraform-aws-template)](https://github.com/DNXLabs/terraform-aws-template/blob/master/LICENSE)

This module is designed to simplify the deployment of Azure DevOps agents on AWS, providing a scalable and manageable solution for CI/CD pipelines.

## Features

-   Creates EC2 instances within an Auto Scaling Group.
-   Supports **x64 (Intel/AMD)** architecture.
-   Configurable Azure DevOps agent version and .NET SDK version.
-   Uses **AWS Systems Manager Session Manager** for secure instance access by default.
-   Optional SSH access with configurable CIDR blocks and key pairs.
-   Installs and configures the CloudWatch agent for logs and basic metrics.
-   Configurable instance type, EBS volume size, and ASG scaling parameters.
-   Applies configurable tags to all created resources.
-   Provides outputs for key resource identifiers.

## Prerequisites

-   Terraform v1.3+
-   AWS Credentials configured for Terraform.
-   Azure DevOps Organization URL.
-   Azure DevOps Personal Access Token (PAT) with **Agent Pools (Read & manage)** scope.
-   VPC and Subnets in your AWS account.

## Usage Example

```hcl
provider "aws" {
  region = "us-east-1"
}

module "azure_devops_agent" {
  source = "github.com/DNXLabs/terraform-azure-devops-self-hosted-agent-on-aws?ref=main"

  #--------------------------------------------------------------
  # General Configuration
  #--------------------------------------------------------------
  name         = "my-ado-agent"
  cluster_name = "dev"
  
  #--------------------------------------------------------------
  # Network Configuration
  #--------------------------------------------------------------
  vpc_id              = "vpc-xxxxxxxxxxxxxxxxx"
  instances_subnet_ids = ["subnet-xxxxxxxxxxxxxxxxx", "subnet-yyyyyyyyyyyyyyyyy"]
  
  #--------------------------------------------------------------
  # Azure DevOps Configuration
  #--------------------------------------------------------------
  azuredevops_url           = "https://dev.azure.com/your-organization"
  azuredevops_token         = "XXXXXXXXXXXXXXXXXXXXXXXXX"
  azuredevops_pool          = "AWS-Linux-Pool"
  azure_devops_agent_version = "4.254.0" # Version of the Azure DevOps agent to install
  
  #--------------------------------------------------------------
  # Instance Configuration 
  #--------------------------------------------------------------
  instance_type        = "t3.medium" # Must be x64 compatible
  
  #--------------------------------------------------------------
  # Auto Scaling Group Configuration
  #--------------------------------------------------------------
  asg_max_size     = 5
  asg_min_size     = 1
  asg_desired_size = 2
  
  #--------------------------------------------------------------
  # Storage Configuration
  #--------------------------------------------------------------
  ebs_volume_size  = 32  # Size in GB for the root EBS volume
  ebs_volume_type  = "gp3" # EBS volume type (gp2, gp3, io1, io2, st1, sc1)
  ebs_volume_iops  = 3000 # IOPS for the EBS volume
  
  #--------------------------------------------------------------
  # Development Tools Configuration
  #--------------------------------------------------------------
  install_dotnet_sdk = true # Set to false to skip .NET installation
  dotnet_sdk_version = "6.0" # .NET SDK version to be pre-installed
  
  #--------------------------------------------------------------
  # Additional Configuration
  #--------------------------------------------------------------
  attach_security_group_ids = [] # List of additional Security Group IDs to attach
  tags = {
    Environment = "dev"
    Project     = "MyApp"
  }
  
  #--------------------------------------------------------------
  # SSH Access Configuration (Optional)
  #--------------------------------------------------------------
  enable_ssh_access = true
  ssh_cidr_blocks   = ["10.0.0.0/16"] # Restrict SSH access to specific IP ranges
  # ssh_key_name    = "my-existing-key" # Uncomment to use an existing key pair
  generate_ssh_key  = true # Generate a new key pair and store in SSM Parameter Store
}
```

## Instance Access

Instance access is managed through **AWS Systems Manager Session Manager** by default. Ensure the IAM role used by your local machine or CI/CD system has permissions to start SSM sessions (`ssm:StartSession`).

**Connect via AWS CLI:**

```bash
aws ssm start-session --target <instance-id>
```

## SSH Access (Optional)

You can optionally enable SSH access to the agent instances by configuring the following variables:

```hcl
module "azure_devops_agent" {
  # ... other configuration ...
  
  # SSH Access Configuration
  enable_ssh_access = true
  ssh_cidr_blocks   = ["10.0.0.0/16", "192.168.1.0/24"] # Restrict SSH access to specific IP ranges
  
  # Option 1: Use an existing key pair
  ssh_key_name      = "my-existing-key-pair"
  generate_ssh_key  = false
  
  # Option 2: Generate a new key pair (default when enable_ssh_access = true)
  # ssh_key_name    = null
  # generate_ssh_key = true
}
```

When `generate_ssh_key` is set to `true`, the module will:
1. Generate a new RSA key pair
2. Store the private key securely in AWS SSM Parameter Store at `/ec2/<cluster_name>/<name>/PRIVATE_KEY`

To retrieve the generated private key:

```bash
aws ssm get-parameter --name "/ec2/<cluster_name>/<name>/PRIVATE_KEY" --with-decryption --query "Parameter.Value" --output text > my-key.pem
chmod 400 my-key.pem
```

Then connect to your instance:

```bash
ssh -i my-key.pem ec2-user@<instance-ip>
```

## Monitoring

-   **Agent Logs:** View agent diagnostic logs in CloudWatch Logs under the log group `/azure-devops-agent/<cluster_name>/<name>/agent-diag`.
-   **User Data Logs:** View the instance setup script logs in CloudWatch Logs under `/azure-devops-agent/<cluster_name>/<name>/userdata`.
-   **Basic Metrics:** View CPU, Memory, and Disk usage metrics in CloudWatch Metrics under the EC2 namespace, filtered by the instance tags.

## Inputs

| Name                       | Description                                                                                                                            | Type          | Default     | Required |
| -------------------------- | -------------------------------------------------------------------------------------------------------------------------------------- | ------------- | ----------- | :------: |
| `name`                     | Name prefix for created AWS resources.                                                                                                 | `string`      | -           |   yes    |
| `cluster_name`             | Identifier for the cluster/environment.                                                                                                | `string`      | -           |   yes    |
| `vpc_id`                   | VPC ID for resource creation.                                                                                                          | `string`      | -           |   yes    |
| `instances_subnet_ids`   | List of private subnet IDs for EC2 instances.                                                                                          | `list(string)`| -           |   yes    |
| `azuredevops_url`          | Azure DevOps organization URL.                                                                                                         | `string`      | -           |   yes    |
| `azuredevops_token`        | Azure DevOps PAT with Agent Pools (Read & manage) scope.                                                                               | `string`      | -           |   yes    |
| `azuredevops_pool`         | Azure DevOps agent pool name.                                                                                                          | `string`      | -           |   yes    |
| `instance_type`            | EC2 instance type (must be compatible with x64 architecture).                                                                          | `string`      | `"t3.small"`|    no    |
| `ebs_volume_size`        | Size (GB) for the root EBS volume.                                                                                                     | `number`      | `32`        |    no    |
| `ebs_volume_type`        | Type of EBS volume for the agent instances. Common types are 'gp2', 'gp3', 'io1', 'io2', 'st1', 'sc1'.                                | `string`      | `"gp3"`     |    no    |
| `ebs_volume_iops`        | IOPS for the EBS volume. Required for 'io1' and 'io2' types.                                                                           | `number`      | `3000`      |    no    |
| `asg_max_size`             | Maximum number of instances in ASG.                                                                                                    | `number`      | `1`         |    no    |
| `asg_min_size`             | Minimum number of instances in ASG.                                                                                                    | `number`      | `1`         |    no    |
| `asg_desired_size`         | Desired number of instances in ASG.                                                                                                    | `number`      | `1`         |    no    |
| `dotnet_sdk_version`       | Full .NET SDK version to install (e.g., '6.0').                                                                                        | `string`      | `"6.0"`     |    no    |
| `install_dotnet_sdk`       | Whether to install the .NET SDK on the agent instances. If false, .NET will not be installed.                                          | `bool`        | `true`      |    no    |
| `azure_devops_agent_version` | Azure DevOps agent version (e.g., '4.254.0').                                                                                        | `string`      | `"4.254.0"` |    no    |
| `attach_security_group_ids`| List of additional Security Group IDs to attach.                                                                                       | `list(string)`| `[]`        |    no    |
| `tags`                     | Map of additional tags for resources.                                                                                                  | `map(string)` | `{}`        |    no    |
| `enable_ssh_access`        | Whether to enable SSH access to the agent instances.                                                                                   | `bool`        | `false`     |    no    |
| `ssh_cidr_blocks`          | List of CIDR blocks allowed to SSH into the agent instances. Only used when enable_ssh_access is true.                                 | `list(string)`| `[]`        |    no    |
| `ssh_key_name`             | Name of an existing SSH key pair to use for the agent instances. If not provided and enable_ssh_access is true, a new key pair will be generated. | `string`      | `null`      |    no    |
| `generate_ssh_key`         | Whether to generate a new SSH key pair for the agent instances. Only used when enable_ssh_access is true and ssh_key_name is not provided. | `bool`        | `true`      |    no    |

## Outputs

| Name                           | Description                                                      |
| ------------------------------ | ---------------------------------------------------------------- |
| `autoscaling_group_name`       | The name of the Auto Scaling Group.                              |
| `autoscaling_group_arn`        | The ARN of the Auto Scaling Group.                               |
| `launch_template_id`           | The ID of the Launch Template.                                   |
| `launch_template_latest_version` | The latest version number of the Launch Template.                |
| `agent_iam_role_arn`           | The ARN of the IAM role assigned to agent instances.             |
| `agent_instance_profile_arn` | The ARN of the IAM instance profile assigned to agent instances. |
| `agent_security_group_id`      | The ID of the Security Group created for agents.                 |
| `cloudwatch_log_group_base`    | The base name for CloudWatch Log Groups created by agents.       |

## Authors

Module managed by [DNX Solutions](https://github.com/DNXLabs).

## License

Apache 2 Licensed. See [LICENSE](https://github.com/DNXLabs/terraform-azure-devops-self-hosted-agent-on-aws/blob/master/LICENSE) for full details.
