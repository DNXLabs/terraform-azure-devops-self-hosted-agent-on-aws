data "aws_region" "current" {}

data "aws_ami" "amazon-linux-2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
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