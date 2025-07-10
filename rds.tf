module "aws_rds_main_dev" {
  source  = "terraform-aws-modules/rds-aurora/aws"
  version = "~> 9.15"

  name           = "main"
  engine         = "aurora-postgresql"
  engine_version = var.postgres_engine_version
  engine_mode    = "provisioned"

  instance_class = "db.serverless"
  instances = {
    one = {}
  }
  serverlessv2_scaling_configuration = {
    min_capacity = 0.5
    max_capacity = 1.0
  }

  vpc_id               = module.aws_vpc_main.vpc_id
  db_subnet_group_name = module.aws_vpc_main.database_subnet_group_name

  security_group_rules = {
    vpc_ingress = {
      cidr_blocks = module.aws_vpc_main.private_subnets_cidr_blocks
    }
  }

  master_username = "root"

  manage_master_user_password                            = true
  manage_master_user_password_rotation                   = true
  master_user_password_rotation_automatically_after_days = 7

  iam_database_authentication_enabled = true

  port = 5432

  enabled_cloudwatch_logs_exports = [
    "postgresql",
  ]

  backup_retention_period      = var.postgres_backup_retention_period
  preferred_maintenance_window = "Mon:03:00-Mon:05:00"
  preferred_backup_window      = "01:00-03:00"
  skip_final_snapshot          = true

  apply_immediately   = false
  deletion_protection = true
}
