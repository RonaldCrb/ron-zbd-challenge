# Production Environment Configuration
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
    key            = "prod/terraform.tfstate"
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
  default     = ""
}

variable "ssh_key_name" {
  description = "Name of the EC2 Key Pair to use for SSH access"
  type        = string
  default     = "ron-zbd-challenge-key"
}

# Locals
locals {
  project_name              = "ron-zbd-challenge"
  environment               = "prod"
  allowed_ssh_cidrs         = var.personal_ip != "" ? [var.personal_ip] : []
  cloudwatch_log_group_name = "/aws/ec2/ron-zbd-challenge-prod"
}


# VPC Module
module "vpc" {
  source = "../../modules/vpc"

  project_name         = local.project_name
  environment          = local.environment
  vpc_cidr            = "10.1.0.0/16"
  public_subnet_cidr  = "10.1.1.0/24"
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
  instance_type             = "t3.small"      # Override default t3.micro for prod
  volume_size               = 50              # Override default 30GB for prod
  key_name                  = var.ssh_key_name
  allowed_ssh_cidrs         = local.allowed_ssh_cidrs
  prometheus_security_group_id = module.instance_b.security_group_id
  cloudwatch_log_group_name = local.cloudwatch_log_group_name
  log_retention_days        = 30              # Override default 14 days for prod

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
  instance_type             = "t3.small"      # Override default t3.micro for prod
  volume_size               = 50              # Override default 30GB for prod
  key_name                  = var.ssh_key_name
  allowed_ssh_cidrs         = local.allowed_ssh_cidrs
  cloudwatch_log_group_name = local.cloudwatch_log_group_name
  log_retention_days        = 30              # Override default 14 days for prod

  depends_on = [module.vpc]
}