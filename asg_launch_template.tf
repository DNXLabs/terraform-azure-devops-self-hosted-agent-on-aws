resource "aws_launch_template" "agent_lt" {
  name_prefix   = "${var.name}-agent-lt-"
  description   = "Launch template for Azure DevOps agent instances in ${var.cluster_name}"
  image_id      = data.aws_ssm_parameter.amazon_linux_2.value
  instance_type = var.instance_type

  # Conditionally set the key_name based on the SSH access configuration
  key_name = var.enable_ssh_access ? (
    var.ssh_key_name != null ? var.ssh_key_name : (
      var.generate_ssh_key ? aws_key_pair.ssh[0].key_name : null
    )
  ) : null

  iam_instance_profile {
    arn = aws_iam_instance_profile.agent_profile.arn
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = var.ebs_volume_size
      volume_type          =  var.ebs_volume_type
      delete_on_termination = true
      encrypted            = true
    }
  }

  vpc_security_group_ids = concat([aws_security_group.agent_sg.id], var.attach_security_group_ids)

  # Enforce IMDSv2 for better security
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  user_data = base64encode(templatefile("${path.module}/userdata.tpl", {
    azuredevops_url            = var.azuredevops_url,
    azuredevops_token          = var.azuredevops_token,
    azuredevops_pool           = var.azuredevops_pool,
    dotnet_sdk_version         = var.dotnet_sdk_version,
    install_dotnet_sdk         = var.install_dotnet_sdk,
    azure_devops_agent_version = var.azure_devops_agent_version,
    cluster_name               = var.cluster_name,
    name                       = var.name
    install_docker             = var.install_docker,
    docker_user_groups         = var.docker_user_groups,
    docker_restart_instance    = var.docker_restart_instance,
    docker_security_acknowledgment = var.docker_security_acknowledgment
  }))

  tags = merge(var.tags, {
    Name = "${var.name}-agent-lt-${var.cluster_name}"
  })

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.tags, {
      Name         = "${var.name}-agent-${var.cluster_name}"
      Cluster      = var.cluster_name
      Architecture = "x64"
    })
  }

  tag_specifications {
    resource_type = "volume"
    tags = merge(var.tags, {
      Name         = "${var.name}-agent-volume-${var.cluster_name}"
      Cluster      = var.cluster_name
      Architecture = "x64"
    })
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "agent_asg" {
  name                      = "${var.name}-agent-asg-${var.cluster_name}"
  max_size                  = var.asg_max_size
  min_size                  = var.asg_min_size
  desired_capacity          = var.asg_desired_size
  health_check_grace_period = 300
  health_check_type         = "EC2"
  vpc_zone_identifier       = var.instances_subnet_ids
  force_delete              = false

  launch_template {
    id      = aws_launch_template.agent_lt.id
    version = "$Latest"
  }

  dynamic "tag" {
    for_each = merge(var.tags, {
      Name         = "${var.name}-agent-${var.cluster_name}",
      Cluster      = var.cluster_name,
      Architecture = "x64"
    })
    content {
      key                 = tag.key
      value              = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [desired_capacity]
  }
}
