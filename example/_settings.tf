provider "aws" {
  region  = local.workspace["region"]
  version = "3.42.0"

  assume_role {
    role_arn = "arn:aws:iam::${local.workspace["aws"]["account_id"]}:role/${local.workspace["aws"]["role"]}"
  }
}

provider "aws" {
  alias   = "us-east-1"
  region  = "us-east-1"
  version = "3.42.0"

  assume_role {
    role_arn = "arn:aws:iam::${local.workspace["aws"]["account_id"]}:role/${local.workspace["aws"]["role"]}"
  }
}
