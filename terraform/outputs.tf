# VPC outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = module.vpc.public_subnet_id
}

# Instance A outputs
output "instance_a_id" {
  description = "ID of instance A"
  value       = module.instance_a.instance_id
}

output "instance_a_public_ip" {
  description = "Public IP address of instance A"
  value       = module.instance_a.instance_public_ip
}

output "instance_a_public_dns" {
  description = "Public DNS name of instance A"
  value       = module.instance_a.instance_public_dns
}

# Instance B outputs
output "instance_b_id" {
  description = "ID of instance B"
  value       = module.instance_b.instance_id
}

output "instance_b_public_ip" {
  description = "Public IP address of instance B"
  value       = module.instance_b.instance_public_ip
}

output "instance_b_public_dns" {
  description = "Public DNS name of instance B"
  value       = module.instance_b.instance_public_dns
}

# Instance URLs
output "instance_urls" {
  description = "Base URLs for the instances"
  value = {
    instance_a = module.instance_a.instance_url
    instance_b = module.instance_b.instance_url
  }
}

# Connection instructions
output "ssh_connection_instructions" {
  description = "Instructions for SSH connection"
  value = {
    instance_a = "ssh -i your-key.pem ec2-user@${module.instance_a.instance_public_ip}"
    instance_b = "ssh -i your-key.pem ec2-user@${module.instance_b.instance_public_ip}"
  }
}

# CloudWatch logs
output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = module.instance_a.cloudwatch_log_group_name
}