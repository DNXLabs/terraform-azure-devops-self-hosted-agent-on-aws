output "autoscaling_group_name" {
  description = "The name of the Auto Scaling Group created."
  value       = aws_autoscaling_group.agent_asg.name
}

output "autoscaling_group_arn" {
  description = "The ARN of the Auto Scaling Group created."
  value       = aws_autoscaling_group.agent_asg.arn
}

output "launch_template_id" {
  description = "The ID of the Launch Template created."
  value       = aws_launch_template.agent_lt.id
}

output "launch_template_latest_version" {
  description = "The latest version number of the Launch Template created."
  value       = aws_launch_template.agent_lt.latest_version
}

output "agent_iam_role_arn" {
  description = "The ARN of the IAM role assigned to the agent instances."
  value       = aws_iam_role.agent_role.arn
}

output "agent_instance_profile_arn" {
  description = "The ARN of the IAM instance profile assigned to the agent instances."
  value       = aws_iam_instance_profile.agent_profile.arn
}

output "agent_security_group_id" {
  description = "The ID of the Security Group created for the agents."
  value       = aws_security_group.agent_sg.id
}

output "cloudwatch_log_group_base" {
  description = "The base name for CloudWatch Log Groups created by the agents."
  value       = "/azure-devops-agent/${var.cluster_name}/${var.name}"
}
