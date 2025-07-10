locals {
  terraform_admins              = ["*:tomislav.kostic@email.com"]
  main_sso_user_access_role_arn = ""
}

data "aws_iam_policy_document" "restrict_s3_backend" {
  statement {
    sid    = "DenyAccessExcept"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = [
      "s3:*",
    ]

    resources = [
      "${module.terraform_state_backend.s3_bucket_arn}/*",
      module.terraform_state_backend.s3_bucket_arn
    ]

    condition {
      test     = "ForAnyValue:StringNotEqualsIfExists"
      variable = "aws:PrincipalArn"
      values = [
        module.aws_iam_assumable_role_main_terraform.iam_role_arn
      ]
    }
  }
}

module "aws_iam_assumable_role_main_terraform" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "~> 5.54"

  create_role = true

  role_name         = "TerraformRole"
  role_requires_mfa = false

  create_custom_role_trust_policy = true
  custom_role_trust_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : [
            local.main_sso_user_access_role_arn,
          ]
        },
        "Action" : ["sts:AssumeRole", "sts:TagSession"]
        "Condition" : {
          "ForAnyValue:StringLikeIfExists" : {
            "aws:userid" : local.terraform_admins
          }
        }
      }
    ]
  })

  custom_role_policy_arns = [
    "arn:aws:iam::aws:policy/AdministratorAccess", # Restrict for least privilege access
  ]
  number_of_custom_role_policy_arns = 1
}
