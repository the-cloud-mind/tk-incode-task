# ——— General ———
variable "region" {
  type    = string
  default = "eu-west-1"
}
variable "environment" {
  type    = string
  default = "test"
}

# ——— VPC ———
variable "vpc_cidr_prefix" {
  type    = string
  default = "10.1"
}

# ——— bastion ———
variable "bastion_instance_type" {
  type    = string
  default = "t3a.micro"
}
variable "bastion_allowed_ssh_cidrs" {
  type        = list(string)
  description = "Allow list of IP addresses for bastion SSH"
  default     = ["0.0.0.0/0"]
}

# ——— demo-app ———
variable "demo_app_instance_type" {
  type    = string
  default = "t3a.small"
}

variable "acm_domains" {
  type = map(any)
  default = {
    tk_example_com = {
      aliases     = ["monitoring.tk-example.com"]
      domain_name = "tk-example.com"
    }
  }
}
