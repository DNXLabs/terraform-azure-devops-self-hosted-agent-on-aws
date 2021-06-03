module "agent_provider" {
  source             = "git::https://github.com/DNXLabs/terraform-azure-devops-self-hosted-agent-on-aws.git?ref=0.1.0"
  cluster_name       = "azure-devops-self-hosted-agent-on-aws"
  name               = "azure-devops"
  vpc_id             = "vpc-XXXXXX"
  instances_subnet   = ["subnet-XXXXXXX", "subnet-XXXXXXX", "subnet-XXXXXXX"]
  azuredevops_url    = "https://dev.azure.com/XXXXXXXX"
  azuredevops_token  = "XXXXXXXXXXXXXXXXXXXXX"
  azuredevops_pool   = "aws_hosted"
  key_name           = "aws_key_name"
  instance_type      = "t3.small"
  asg_max_size       = 2
  asg_min_size       = 2
  asg_desired_size   = 2
  dotnet_sdk_version = "2.2"
  sg_cidr_blocks     = ["XXX.XXX.XX.XXX/XX"]
}