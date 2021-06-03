resource "aws_autoscaling_group" "agent_asg" {
  name                      = "azure_devops_agent_asg"
  max_size                  = var.asg_max_size
  min_size                  = var.asg_min_size
  health_check_grace_period = 300
  health_check_type         = "EC2"
  desired_capacity          = var.asg_desired_size
  force_delete              = false
  vpc_zone_identifier       = var.instances_subnet

  launch_template {
    id      = aws_launch_template.default.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "Azure Devops Build Agent"
    propagate_at_launch = true
  }
}


resource "aws_launch_template" "default" {
  name_prefix   = "${var.name}-"
  image_id      = data.aws_ami.amazon-linux-2.image_id
  instance_type = var.instance_type

  iam_instance_profile {
    name = aws_iam_instance_profile.default.name
  }

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size = var.ebs_size
    }
  }

  key_name = aws_key_pair.default.id

  vpc_security_group_ids = concat(list(aws_security_group.default.id), var.security_group_ids)

  user_data = base64encode(templatefile("${path.module}/userdata.tpl", { url = "${var.azuredevops_url}", token = "${var.azuredevops_token}", pool = "${var.azuredevops_pool}", dotnet_sdk_version = "${var.dotnet_sdk_version}" }))


  lifecycle {
    create_before_destroy = true
  }
}

resource "tls_private_key" "default" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "default" {
  key_name   = var.name
  public_key = tls_private_key.default.public_key_openssh
}

resource "aws_ssm_parameter" "default_private_key" {
  name  = "/ec2/${var.cluster_name}/${var.name}/PRIVATE_KEY"
  type  = "SecureString"
  value = tls_private_key.default.private_key_pem
  lifecycle {
    ignore_changes = [value]
  }
}