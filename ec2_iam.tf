resource "aws_iam_instance_profile" "default" {
  name = "${var.name}-${data.aws_region.current.name}"
  role = aws_iam_role.default.name
}

resource "aws_iam_role" "default" {
  name = "${var.name}-${data.aws_region.current.name}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "default_ssm" {
  role       = aws_iam_role.default.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}

resource "aws_iam_role_policy" "assume_role" {
  name = "assume_role"
  role = aws_iam_role.default.name

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "",
        "Effect" : "Allow",
        "Action" : "sts:AssumeRole",
        "Resource" : "arn:aws:iam::*:role/CIDeployAccess"
      }
    ]
  })
}

resource "aws_iam_role" "agent_role" {
  name = "${var.name}-agent-role-${data.aws_region.current.name}"
  path = "/"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.name}-agent-role-${var.cluster_name}"
  })
}

resource "aws_iam_instance_profile" "agent_profile" {
  name = "${var.name}-agent-${data.aws_region.current.name}"
  role = aws_iam_role.agent_role.name

  tags = merge(var.tags, {
    Name = "${var.name}-agent-${var.cluster_name}"
  })
}

# Required policy for SSM Session Manager & basic EC2 operations
resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.agent_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Required policy for CloudWatch Agent
resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  role       = aws_iam_role.agent_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Required policy for Secret Manager
resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.agent_role.name
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
}