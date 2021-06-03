# terraform-azure-devops-self-hosted-agent-on-aws

[![Lint Status](https://github.com/DNXLabs/terraform-aws-template/workflows/Lint/badge.svg)](https://github.com/DNXLabs/terraform-aws-template/actions)
[![LICENSE](https://img.shields.io/github/license/DNXLabs/terraform-aws-template)](https://github.com/DNXLabs/terraform-aws-template/blob/master/LICENSE)

<!--- BEGIN_TF_DOCS --->

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.13.0 |

## Providers

| Name | Version |
|------|---------|
| aws | n/a |
| tls | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| asg\_desired\_size | Desired size for ASG | `number` | `1` | no |
| asg\_max\_size | Maximum size for ASG | `number` | `1` | no |
| asg\_min\_size | Minimum size for ASG | `number` | `1` | no |
| azuredevops\_pool | Azure devops pool name for the agents | `string` | n/a | yes |
| azuredevops\_token | Azure devops personal access token for agent registration | `string` | n/a | yes |
| azuredevops\_url | Azure devops url for your organisation | `string` | n/a | yes |
| cluster\_name | Environment name | `any` | n/a | yes |
| dotnet\_sdk\_version | Dotnet sdk version to be pre-installed into the agents | `string` | `"3.1"` | no |
| ebs\_size | EBS size in GB for agent instances | `number` | `32` | no |
| instance\_type | EC2 instance type | `string` | `"t3.small"` | no |
| instances\_subnet | List of private subnet IDs for EC2 instances | `list(any)` | n/a | yes |
| key\_name | Key-Pair name for access into the agent instances | `string` | n/a | yes |
| name | Name of this EC2 cluster | `any` | n/a | yes |
| security\_group\_ids | Extra security groups for instances | `list(any)` | `[]` | no |
| sg\_cidr\_blocks | List of cidr blocks for SSH access to the build agents | `list(any)` | <pre>[<br>  ""<br>]</pre> | no |
| vpc\_id | VPC id for the instances | `string` | n/a | yes |

## Outputs

No output.

<!--- END_TF_DOCS --->

## Authors

Module managed by [DNX Solutions](https://github.com/DNXLabs).

## License

Apache 2 Licensed. See [LICENSE](https://github.com/DNXLabs/terraform-azure-devops-self-hosted-agent-on-aws/blob/master/LICENSE) for full details.
