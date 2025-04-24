data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# Use x86_64 architecture for AMI selection
locals {
  al2_ami_ssm_parameter_name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

# Use the aws_ssm_parameter data source to get the latest AL2 AMI ID
data "aws_ssm_parameter" "amazon_linux_2" {
  name = local.al2_ami_ssm_parameter_name
}

data "aws_autoscaling_groups" "groups" {
  filter {
    name   = "key"
    values = ["Name"]
  }

  filter {
    name   = "value"
    values = ["${var.name}-*"]
  }
}
