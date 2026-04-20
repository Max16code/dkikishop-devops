terraform {
  backend "s3" {
    bucket         = "devops-showcase-tf-state-YOUR-UNIQUE-ID"  # Must match variable
    key            = "devops-showcase.tfstate"
    region         = "us-east-1"
    dynamodb_table = "devops-tf-lock"
    encrypt        = true
  }
}