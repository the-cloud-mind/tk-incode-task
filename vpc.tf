
module "aws_vpc_main" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.21"

  name = "main-vpc"
  cidr = "${var.vpc_cidr_prefix}.0.0/16"
  azs  = slice(data.aws_availability_zones.available.names, 0, 2)

  public_subnets = [
    "${var.vpc_cidr_prefix}.0.0/24",
    "${var.vpc_cidr_prefix}.1.0/24",
  ]
  private_subnets = [
    "${var.vpc_cidr_prefix}.64.0/24",
    "${var.vpc_cidr_prefix}.65.0/24",
  ]
  database_subnets = [
    "${var.vpc_cidr_prefix}.128.0/24",
    "${var.vpc_cidr_prefix}.129.0/24",
  ]

  create_igw             = true
  enable_nat_gateway     = true
  single_nat_gateway     = false
  one_nat_gateway_per_az = true


  public_subnet_tags = {
    "tk:subnet-type" : "public"
  }
  private_subnet_tags = {
    "tk:subnet-type" : "private"
  }
  database_subnet_tags = {
    "tk:subnet-type" : "database"
  }
}
