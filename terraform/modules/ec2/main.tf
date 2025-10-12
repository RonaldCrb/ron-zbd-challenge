# Security Group
resource "aws_security_group" "ec2" {
  name_prefix = "${var.project_name}-ec2-"
  vpc_id      = var.vpc_id

  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidrs
  }

  # HTTP access
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_http_cidrs
  }

  # HTTPS access
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_https_cidrs
  }

  # Application port (8080 for the API server)
  dynamic "ingress" {
    for_each = var.prometheus_security_group_id != null ? [1] : []
    content {
      from_port       = 8080
      to_port         = 8080
      protocol        = "tcp"
      security_groups = [var.prometheus_security_group_id]
    }
  }

  # HTTP access for general API access
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = var.allowed_app_cidrs
  }

  # Prometheus port (9090)
  ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = var.allowed_app_cidrs
  }

  # All outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-ec2-sg"
    Environment = var.environment
    Project     = var.project_name
  }
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "app_logs" {
  name              = var.cloudwatch_log_group_name
  retention_in_days = var.log_retention_days

  tags = {
    Name        = "${var.project_name}-logs"
    Environment = var.environment
    Project     = var.project_name
  }
}

# IAM Role for EC2 instance
resource "aws_iam_role" "ec2_role" {
  name = "${var.project_name}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-ec2-role"
    Environment = var.environment
    Project     = var.project_name
  }
}

# IAM Policy for CloudWatch Logs
resource "aws_iam_policy" "cloudwatch_logs" {
  name        = "${var.project_name}-cloudwatch-logs"
  description = "Policy for CloudWatch Logs access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = [
          "arn:aws:logs:*:*:log-group:${var.cloudwatch_log_group_name}*"
        ]
      }
    ]
  })
}

# Attach CloudWatch policy to role
resource "aws_iam_role_policy_attachment" "cloudwatch_logs" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.cloudwatch_logs.arn
}

# Attach SSM policy for session manager
resource "aws_iam_role_policy_attachment" "ssm_managed_instance_core" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Instance Profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-ec2-profile"
  role = aws_iam_role.ec2_role.name

  tags = {
    Name        = "${var.project_name}-ec2-profile"
    Environment = var.environment
    Project     = var.project_name
  }
}

# EC2 Instance
resource "aws_instance" "main" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.ec2.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name
  user_data              = base64encode(templatefile("${path.module}/user_data.sh", {
    log_group_name = aws_cloudwatch_log_group.app_logs.name
    instance_name  = var.instance_name
  }))

  root_block_device {
    volume_type           = var.volume_type
    volume_size           = var.volume_size
    delete_on_termination = var.delete_on_termination
    encrypted             = var.volume_encrypted

    tags = {
      Name        = "${var.project_name}-${var.instance_name}-root"
      Environment = var.environment
      Project     = var.project_name
    }
  }

  tags = {
    Name        = var.instance_name
    Environment = var.environment
    Project     = var.project_name
    Type        = var.instance_name
  }
}