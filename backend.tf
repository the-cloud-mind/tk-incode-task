# terraform {
#   required_version = ">= 1.0.0"

#   backend "s3" {
#     region   = "eu-west-1"
#     bucket   = "tk-main-terraform-state"
#     key      = "task/terraform.state"
#     profile  = ""
#     encrypt  = "true"
#     role_arn = "arn:aws:iam::xxxxxyyyyyy:role/TerraformRole"

#     dynamodb_table = "tk-main-terraform-state-lock"
#   }
# }
