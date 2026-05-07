terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

module "networking" {
  source = "./modules/networking"
  
  environment           = var.environment
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
}

module "compute" {
  source = "./modules/compute"
  
  environment            = var.environment
  vpc_id                 = module.networking.vpc_id
  public_subnet_ids      = module.networking.public_subnet_ids
  private_subnet_ids     = module.networking.private_subnet_ids
  alb_security_group_id  = module.networking.alb_security_group_id
  ec2_security_group_id  = module.networking.ec2_security_group_id
  target_group_arn       = module.networking.target_group_arn
  docker_image           = var.docker_image
  instance_type          = var.instance_type
  key_name               = var.key_name
  min_size               = var.min_size
  max_size               = var.max_size
  desired_capacity       = var.desired_capacity
  aws_region             = var.aws_region
  account_id             = data.aws_caller_identity.current.account_id
}

data "aws_caller_identity" "current" {}
