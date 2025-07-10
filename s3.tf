module "aws_s3_tk_access_logs" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 4.11"

  bucket = "tk-access-logs"
}

module "aws_s3_tk_demo_app" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 4.11"

  bucket = "tk-demo-app"
}
