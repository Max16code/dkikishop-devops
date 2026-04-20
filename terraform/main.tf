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

# VPC Module
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
  single_nat_gateway = false
  create_igw         = true
}

# S3 Bucket for Terraform Remote State
resource "aws_s3_bucket" "tf_state" {
  bucket = var.tf_state_bucket

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# DynamoDB for State Locking
resource "aws_dynamodb_table" "tf_lock" {
  name         = "devops-tf-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "Terraform State Lock"
    Environment = "DevOps-Showcase"
  }
}

# Security Group
resource "aws_security_group" "ec2_sg" {
  name        = "devops-showcase-sg"
  description = "Security group for DevOps Showcase EC2"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "SSH from anywhere (restrict in production)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
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
    Name = "devops-showcase-sg"
  }
}

# Latest Amazon Linux 2023 AMI
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# EC2 Instance
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
    dnf install -y docker
    systemctl enable --now docker
    usermod -aG docker ec2-user

    # Docker will be started manually by GitHub Actions after deployment
  EOF

  tags = {
    Name        = "devops-showcase-ec2"
    Environment = "DevOps-Showcase"
  }
}

output "ec2_public_ip" {
  value       = aws_instance.app_server.public_ip
  description = "Public IP of the EC2 instance - Add this to GitHub Secrets as EC2_PUBLIC_IP"
}

output "vpc_id" {
  value = module.vpc.vpc_id
}