module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 5.2"

  for_each = var.acm_domains

  domain_name               = each.value.domain_name
  subject_alternative_names = try(each.value.aliases, [])

  validation_method = "DNS"

  wait_for_validation = false

  tags = {
    Name = each.value.domain_name
  }
}

