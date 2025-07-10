resource "aws_security_group" "bastion" {
  name        = "bastion-sg"
  description = "Allow SSH from trusted sources"
  vpc_id      = module.aws_vpc_main.vpc_id

  ingress {
    description = "Allow SSH connection from allowed IP addresses"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.bastion_allowed_ssh_cidrs
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "bastion-sg"
  }
}

module "aws_ssh_key_bastion" {
  source  = "terraform-aws-modules/key-pair/aws"
  version = "~> 2.1"

  key_name           = "bastion"
  create_private_key = true
}

resource "aws_instance" "bastion" {
  ami           = data.aws_ssm_parameter.al2023.value
  key_name      = module.aws_ssh_key_bastion.key_pair_name
  instance_type = var.bastion_instance_type

  associate_public_ip_address = true

  root_block_device {
    volume_size           = 8
    encrypted             = true
    volume_type           = "gp3"
    delete_on_termination = false
  }

  subnet_id              = module.aws_vpc_main.public_subnets[0]
  vpc_security_group_ids = [resource.aws_security_group.bastion.id]

  tags = {
    "Name" = "bastion"
  }
}

resource "aws_eip" "bastion_eip" {
  domain   = "vpc"
  instance = aws_instance.bastion.id
  tags = {
    Name = "bastion-eip"
  }
}

output "bastion_public_ip" {
  description = "Public IP of the bastion host"
  value       = aws_eip.bastion_eip.public_ip
}

output "bastion_ssh_keys" {
  value = {
    private_key_pem     = module.aws_ssh_key_bastion.private_key_pem
    public_key_pem      = module.aws_ssh_key_bastion.public_key_pem
    key_pair_name       = module.aws_ssh_key_bastion.key_pair_name
    private_key_openssh = module.aws_ssh_key_bastion.private_key_openssh
    public_key_openssh  = module.aws_ssh_key_bastion.public_key_openssh
  }
  sensitive = true
}
