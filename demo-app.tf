# ——— IAM Roles ——— #
resource "aws_iam_role" "demo_app" {
  name = "DemoApp"
  assume_role_policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Action" : "sts:AssumeRole",
          "Principal" : {
            "Service" : "ec2.amazonaws.com"
          },
          "Effect" : "Allow",
          "Sid" : ""
        }
      ]
  })
}
resource "aws_iam_policy" "s3_read_demo_app" {
  name        = "s3ReadDemoApp"
  description = "Allow Woodpecker EC2 agents to read the agent secret"

  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : [
            "s3:Get*",
            "s3:List*",
            "s3:Describe*"
          ],
          "Resource" : [
            "${module.aws_s3_tk_demo_app.s3_bucket_arn}",
            "${module.aws_s3_tk_demo_app.s3_bucket_arn}/"
          ]
        }
      ]
  })
}
resource "aws_iam_policy_attachment" "s3_read_demo_app" {
  name       = "s3ReadDemoApp"
  roles      = [aws_iam_role.demo_app.name]
  policy_arn = aws_iam_policy.s3_read_demo_app.arn
}

resource "aws_iam_instance_profile" "demo_app" {
  name = "DemoApp"
  role = aws_iam_role.demo_app.name
}
### ———————————— ###

resource "aws_security_group" "demo_app" {
  name        = "demo-app-sg"
  description = "Allow access for demo-app instance"
  vpc_id      = module.aws_vpc_main.vpc_id

  ingress {
    description = "Allow SSH connection from bastion"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${aws_instance.bastion.private_ip}/32"]
  }
  ingress {
    description = "Allow access to demo-app"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [module.aws_vpc_main.vpc_cidr_block]
  }
  ingress {
    description     = "Allow HTTP from ALB"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [module.alb.security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "demo-app-sg"
  }
}

module "aws_ssh_key_demo_app" {
  source  = "terraform-aws-modules/key-pair/aws"
  version = "~> 2.1"

  key_name           = "demo-app"
  create_private_key = true
}

resource "aws_instance" "demo_app" {
  ami           = data.aws_ssm_parameter.al2023.value
  key_name      = module.aws_ssh_key_demo_app.key_pair_name
  instance_type = var.demo_app_instance_type

  iam_instance_profile = aws_iam_instance_profile.demo_app.name

  root_block_device {
    volume_size           = 20
    encrypted             = true
    volume_type           = "gp3"
    delete_on_termination = false
  }

  subnet_id              = module.aws_vpc_main.private_subnets[0]
  vpc_security_group_ids = [resource.aws_security_group.demo_app.id]

  user_data = file("${path.module}/userdata/init_demo_app.sh")

  tags = {
    "Name" = "demo-app"
  }
}

output "demo_app_ssh_keys" {
  value = {
    private_key_pem     = module.aws_ssh_key_demo_app.private_key_pem
    public_key_pem      = module.aws_ssh_key_demo_app.public_key_pem
    key_pair_name       = module.aws_ssh_key_demo_app.key_pair_name
    private_key_openssh = module.aws_ssh_key_demo_app.private_key_openssh
    public_key_openssh  = module.aws_ssh_key_demo_app.public_key_openssh
  }
  sensitive = true
}

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 9.17"

  name = "demo-app-alb"

  load_balancer_type = "application"
  vpc_id             = module.aws_vpc_main.vpc_id
  subnets            = module.aws_vpc_main.public_subnets

  security_group_ingress_rules = {
    all_http = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      description = "HTTP web traffic"
      cidr_ipv4   = "0.0.0.0/0"
    }
    all_https = {
      from_port   = 443
      to_port     = 443
      ip_protocol = "tcp"
      description = "HTTPS web traffic"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }
  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = module.aws_vpc_main.vpc_cidr_block
    }
  }

  access_logs = {
    bucket = "tk-acces-logs"
    prefix = "alb-access-logs"
  }

  listeners = {
    http-https-redirect = {
      port     = 80
      protocol = "HTTP"
      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
    https = {
      port            = 443
      protocol        = "HTTPS"
      ssl_policy      = "ELBSecurityPolicy-TLS13-1-2-Res-2021-06"
      certificate_arn = module.acm["tk_example_com"].acm_certificate_arn

      forward = {
        target_group_key = "demo_app_tg"
      }

      rules = {
        grafana = {
          priority = 50

          actions = [{
            type             = "forward"
            target_group_key = "grafana_tg"
          }]

          conditions = [{
            host_header = {
              values = ["monitoring.tk-example.com"]
            }
          }]
        }
      }
    }
  }

  target_groups = {
    demo_app_tg = {
      name             = "demo-app-tg"
      backend_protocol = "HTTP"
      target_type      = "instance"
      target_id        = aws_instance.demo_app.id
      port             = 8080

      health_check = {
        enabled             = true
        path                = "/healthy"
        protocol            = "HTTP"
        matcher             = "200"
        interval            = 30
        timeout             = 6
        healthy_threshold   = 3
        unhealthy_threshold = 3
      }
    }
    grafana_tg = {
      name             = "grafana-tg"
      backend_protocol = "HTTP"
      target_type      = "instance"
      target_id        = aws_instance.demo_app.id
      port             = 3001

      health_check = {
        enabled             = true
        path                = "/"
        protocol            = "HTTP"
        matcher             = "200-399"
        interval            = 30
        timeout             = 5
        healthy_threshold   = 2
        unhealthy_threshold = 2
      }
    }
  }

  tags = {
    Name = "demo-app-alb"
  }
}
