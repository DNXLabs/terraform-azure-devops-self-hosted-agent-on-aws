terraform {
  required_version = ">= 1.3" 

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Default AWS provider using the region from local.workspace
provider "aws" {
  region = local.workspace["region"]
}

locals {
  # Workspace-specific configuration values
  workspace = {
    # Default AWS region for this deployment
    region = "ap-southeast-2" 
}
}