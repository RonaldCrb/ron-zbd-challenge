# Locals
locals {
  project_name              = "ron-zbd-challenge"
  environment               = "dev"
  allowed_ssh_cidrs         = ["129.224.209.181/0"]  # WARNING: Replace with your IP!
  cloudwatch_log_group_name = "/aws/ec2/ron-zbd-challenge"
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

# VPC Module
module "vpc" {
  source = "./modules/vpc"

  project_name         = local.project_name
  environment          = local.environment
  vpc_cidr            = "10.0.0.0/16"
  public_subnet_cidr  = "10.0.1.0/24"
  availability_zone   = data.aws_availability_zones.available.names[0]
}

# EC2 Instance A (API Server)
module "instance_a" {
  source = "./modules/ec2"
  depends_on = [module.vpc]

  instance_name             = "instance-a"
  project_name              = local.project_name
  environment               = local.environment
  vpc_id                    = module.vpc.vpc_id
  subnet_id                 = module.vpc.public_subnet_id
  ami_id                    = data.aws_ami.amazon_linux_2023.id
  allowed_ssh_cidrs         = local.allowed_ssh_cidrs
  prometheus_security_group_id = module.instance_b.security_group_id
  cloudwatch_log_group_name = local.cloudwatch_log_group_name
}

# EC2 Instance B (Prometheus)
module "instance_b" {
  source = "./modules/ec2"
  depends_on = [module.vpc]

  instance_name             = "instance-b"
  project_name              = local.project_name
  environment               = local.environment
  vpc_id                    = module.vpc.vpc_id
  subnet_id                 = module.vpc.public_subnet_id
  ami_id                    = data.aws_ami.amazon_linux_2023.id
  allowed_ssh_cidrs         = local.allowed_ssh_cidrs
  cloudwatch_log_group_name = local.cloudwatch_log_group_name
}