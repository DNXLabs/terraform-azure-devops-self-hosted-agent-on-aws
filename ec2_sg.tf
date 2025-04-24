resource "aws_security_group" "agent_sg" {
  name        = "${var.name}-agent-sg-${var.cluster_name}"
  description = "Security Group for Azure DevOps agent instances in ${var.cluster_name}"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.name}-agent-sg-${var.cluster_name}"
  })
}

# Allow all outbound traffic (typical for build agents needing internet access)
resource "aws_security_group_rule" "allow_all_egress" {
  security_group_id = aws_security_group.agent_sg.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow all outbound traffic"
}

# Allow instances within the same SG to communicate with each other (optional)
resource "aws_security_group_rule" "allow_self_ingress" {
  security_group_id        = aws_security_group.agent_sg.id
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.agent_sg.id
  description              = "Allow instances within this SG to communicate"
}

# Conditionally allow SSH access
resource "aws_security_group_rule" "allow_ssh_ingress" {
  count             = var.enable_ssh_access ? 1 : 0
  security_group_id = aws_security_group.agent_sg.id
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = var.ssh_cidr_blocks
  description       = "Allow SSH access from specified CIDR blocks"
}
