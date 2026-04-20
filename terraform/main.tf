terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# ------------------------
# VPC
# ------------------------
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.6.1"

  name = "devops-showcase-vpc"
  cidr = "10.0.0.0/16"

  azs            = ["${var.region}a", "${var.region}b"]
  public_subnets = ["10.0.1.0/24", "10.0.2.0/24"]

  map_public_ip_on_launch = true
  enable_dns_hostnames    = true
  enable_dns_support      = true

  enable_nat_gateway = false
  create_igw         = true

  tags = {
    Project = "devops-showcase"
  }
}

# ------------------------
# Security Group
# ------------------------
resource "aws_security_group" "ec2_sg" {
  name        = "devops-showcase-sg"
  description = "Allow SSH, HTTP, HTTPS"
  vpc_id      = module.vpc.vpc_id

  # 🔐 Restrict SSH (CHANGE THIS IP)
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["YOUR_PUBLIC_IP/32"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Project = "devops-showcase"
  }
}

# ------------------------
# Latest Amazon Linux 2023
# ------------------------
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

# ------------------------
# EC2 Instance
# ------------------------
resource "aws_instance" "app_server" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = var.instance_type
  subnet_id                   = module.vpc.public_subnets[0]
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  key_name                    = var.key_name
  associate_public_ip_address = true

  user_data = <<-EOF
    #!/bin/bash
    dnf update -y

    # Install Docker
    dnf install -y docker
    systemctl enable --now docker
    usermod -aG docker ec2-user

    # Install Nginx
    dnf install -y nginx
    systemctl enable --now nginx

    # Configure Reverse Proxy
    cat > /etc/nginx/conf.d/app.conf <<EOT
    server {
        listen 80;

        location / {
            proxy_pass http://localhost:3000;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
        }
    }
    EOT

    systemctl restart nginx
  EOF

  tags = {
    Name    = "devops-showcase-ec2"
    Project = "devops-showcase"
  }
}

# ------------------------
# Elastic IP (STATIC IP)
# ------------------------
resource "aws_eip" "app_eip" {
  instance = aws_instance.app_server.id

  tags = {
    Project = "devops-showcase"
  }
}

# ------------------------
# Outputs
# ------------------------
output "ec2_public_ip" {
  value = aws_eip.app_eip.public_ip
}

output "app_url" {
  value = "http://${aws_eip.app_eip.public_ip}"
}

output "ssh_command" {
  value = "ssh -i ~/.ssh/${var.key_name}.pem ec2-user@${aws_eip.app_eip.public_ip}"
}