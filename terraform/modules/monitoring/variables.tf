variable "environment" {
  type = string
}

variable "alb_arn_suffix" {
  type = string
}

variable "asg_name" {
  type = string
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}