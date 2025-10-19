terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.4"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

resource "local_file" "whoami" {
  filename = "whoami.txt"
  content  = <<EOT
Account ID: ${data.aws_caller_identity.current.account_id}
ARN:        ${data.aws_caller_identity.current.arn}
UserId:     ${data.aws_caller_identity.current.user_id}
EOT
}
