terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.100"
    }
  }
}

provider "aws" {
  region = var.region
  default_tags {
    tags = {
      "tk:environment" = var.environment
      "tk:terraform"   = "true"
    }
  }
  # assume_role {
  #   role_arn = "arn:aws:iam::xxxxxyyyyyy:role/TerraformRole"
  # }
}
