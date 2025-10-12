variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where instance will be created"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID where instance will be created"
  type        = string
}

variable "ami_id" {
  description = "AMI ID for the EC2 instance"
  type        = string
}

variable "instance_name" {
  description = "Name of the EC2 instance"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "volume_type" {
  description = "Type of the root volume"
  type        = string
  default     = "gp3"
}

variable "volume_size" {
  description = "Size of the root volume in GB"
  type        = number
  default     = 30
}

variable "delete_on_termination" {
  description = "Whether to delete the volume on instance termination"
  type        = bool
  default     = true
}

variable "volume_encrypted" {
  description = "Whether to encrypt the root volume"
  type        = bool
  default     = true
}

variable "allowed_ssh_cidrs" {
  description = "CIDR blocks allowed to SSH to instance"
  type        = list(string)
}

variable "allowed_http_cidrs" {
  description = "CIDR blocks allowed HTTP access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "allowed_https_cidrs" {
  description = "CIDR blocks allowed HTTPS access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "allowed_app_cidrs" {
  description = "CIDR blocks allowed application access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "prometheus_security_group_id" {
  description = "Security group ID for Prometheus instance (for /metrics access)"
  type        = string
  default     = null
}

variable "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group"
  type        = string
}

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 14
}

variable "key_name" {
  description = "Name of the EC2 Key Pair to use for SSH access"
  type        = string
  default     = null
}