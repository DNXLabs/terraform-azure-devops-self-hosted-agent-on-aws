# Only create these resources if SSH access is enabled and we need to generate a key
resource "tls_private_key" "ssh" {
  count     = var.enable_ssh_access && var.generate_ssh_key && var.ssh_key_name == null ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "ssh" {
  count      = var.enable_ssh_access && var.generate_ssh_key && var.ssh_key_name == null ? 1 : 0
  key_name   = "${var.name}-${var.cluster_name}-key"
  public_key = tls_private_key.ssh[0].public_key_openssh
}

resource "aws_ssm_parameter" "ssh_private_key" {
  count = var.enable_ssh_access && var.generate_ssh_key && var.ssh_key_name == null ? 1 : 0
  name  = "/ec2/${var.cluster_name}/${var.name}/PRIVATE_KEY"
  type  = "SecureString"
  value = tls_private_key.ssh[0].private_key_pem
  
  lifecycle {
    ignore_changes = [value]
  }
}
