# Development Environment Configuration
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  backend "s3" {
    bucket         = "ron-zbd-challenge-terraform-state"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
  }
}

provider "aws" {
  region = "us-east-1"
}

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Variables
variable "personal_ip" {
  description = "Your personal IP address for SSH access (e.g., 1.2.3.4/32)"
  type        = string
}

variable "ssh_key_name" {
  description = "Name of the EC2 Key Pair to use for SSH access"
  type        = string
  default     = "ron-zbd-challenge-key"
}

# Locals
locals {
  project_name              = "ron-zbd-challenge"
  environment               = "dev"
  allowed_ssh_cidrs         = var.personal_ip != "" ? [var.personal_ip] : []
  cloudwatch_log_group_name = "/aws/ec2/ron-zbd-challenge-dev"
}


# VPC Module
module "vpc" {
  source = "../../modules/vpc"

  project_name         = local.project_name
  environment          = local.environment
  vpc_cidr            = "10.0.0.0/16"
  public_subnet_cidr  = "10.0.1.0/24"
  availability_zone   = data.aws_availability_zones.available.names[0]
}

# EC2 Instance A (API Server)
module "instance_a" {
  source = "../../modules/ec2"

  project_name              = local.project_name
  environment               = local.environment
  vpc_id                    = module.vpc.vpc_id
  subnet_id                 = module.vpc.public_subnet_id
  ami_id                    = data.aws_ami.amazon_linux_2023.id
  instance_name             = "instance-a"
  volume_size               = 30  # Minimum required for Amazon Linux 2023
  key_name                  = var.ssh_key_name
  allowed_ssh_cidrs         = local.allowed_ssh_cidrs
  prometheus_security_group_id = module.instance_b.security_group_id
  cloudwatch_log_group_name = local.cloudwatch_log_group_name

  depends_on = [module.vpc]
}

# EC2 Instance B (Prometheus)
module "instance_b" {
  source = "../../modules/ec2"

  project_name              = local.project_name
  environment               = local.environment
  vpc_id                    = module.vpc.vpc_id
  subnet_id                 = module.vpc.public_subnet_id
  ami_id                    = data.aws_ami.amazon_linux_2023.id
  instance_name             = "instance-b"
  volume_size               = 30  # Minimum required for Amazon Linux 2023
  key_name                  = var.ssh_key_name
  allowed_ssh_cidrs         = local.allowed_ssh_cidrs
  cloudwatch_log_group_name = local.cloudwatch_log_group_name

  depends_on = [module.vpc]
}