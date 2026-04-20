variable "region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"
}

variable "tf_state_bucket" {
  description = "Unique name for S3 Terraform state bucket"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "Name of the SSH key pair in AWS"
  type        = string
}
