module "terraform_state_backend" {
  source  = "cloudposse/tfstate-backend/aws"
  version = "~> 1.5"

  namespace  = "tk"
  stage      = "main"
  name       = "terraform"
  attributes = ["state"]

  source_policy_documents = [
    data.aws_iam_policy_document.restrict_s3_backend.json
  ]

  terraform_backend_config_file_path = "./backends"
  terraform_backend_config_file_name = "main.tf"
  force_destroy                      = false
}
