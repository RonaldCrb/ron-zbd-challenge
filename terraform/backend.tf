# S3 Backend Configuration
terraform {
  backend "s3" {
    bucket         = "ron-zbd-challenge-terraform-state"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
  }
}
