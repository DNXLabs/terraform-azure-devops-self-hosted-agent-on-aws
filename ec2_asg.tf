resource "aws_security_group" "default" {
  name        = var.name
  description = "SG for ${var.name}"
  vpc_id      = var.vpc_id

  tags = {
    Name = var.name
  }
}

resource "aws_security_group_rule" "default_ingress" {
  description              = "Traffic between ${var.name}"
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.default.id
  source_security_group_id = aws_security_group.default.id
}

resource "aws_security_group_rule" "ssh_ingress" {
  description              = "SSH Ingress"
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "-1"
  cidr_blocks              = var.sg_cidr_blocks
  security_group_id        = aws_security_group.default.id
}

resource "aws_security_group_rule" "default_egress" {
  description       = "Traffic to internet"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.default.id
  cidr_blocks       = ["0.0.0.0/0"]
}