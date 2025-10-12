#!/bin/bash

# Deployment script for Ron ZBD Challenge Infrastructure
set -e

echo "🚀 Starting deployment of Ron ZBD Challenge infrastructure..."

# Check if terraform is installed
if ! command -v terraform &> /dev/null; then
    echo "❌ Terraform is not installed. Please install Terraform first."
    exit 1
fi

# Check if AWS CLI is configured
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS CLI is not configured or credentials are invalid."
    echo "Please run 'aws configure' first."
    exit 1
fi

# Check if personal IP needs to be configured
echo "⚠️  IMPORTANT: Please update the allowed_ssh_cidrs in main.tf with your personal IP address!"
echo "   Edit the allowed_ssh_cidrs line to use your IP instead of '0.0.0.0/0'"
echo "   Example: allowed_ssh_cidrs = [\"YOUR_IP_HERE/32\"]"
echo ""
read -p "Have you updated the SSH CIDR blocks in main.tf? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Please update main.tf with your personal IP address first."
    exit 1
fi

echo "✅ Prerequisites check passed"

# Initialize Terraform
echo "🔧 Initializing Terraform..."
terraform init

# Plan the deployment
echo "📋 Planning deployment..."
terraform plan

# Ask for confirmation
echo ""
read -p "🤔 Do you want to proceed with the deployment? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Deployment cancelled."
    exit 1
fi

# Apply the configuration
echo "🚀 Deploying infrastructure..."
terraform apply -auto-approve

# Display outputs
echo ""
echo "✅ Deployment completed successfully!"
echo ""
echo "📊 Infrastructure outputs:"
terraform output

echo ""
echo "🔗 Infrastructure URLs:"
echo "Instance A: http://$(terraform output -raw instance_a_public_ip) (Ready for application deployment)"
echo "Instance B: http://$(terraform output -raw instance_b_public_ip) (Ready for application deployment)"

echo ""
echo "🔐 SSH Access:"
echo "Instance A: $(terraform output -json ssh_connection_instructions | jq -r '.instance_a')"
echo "Instance B: $(terraform output -json ssh_connection_instructions | jq -r '.instance_b')"

echo ""
echo "📝 CloudWatch Logs:"
echo "Log Group: $(terraform output -raw cloudwatch_log_group_name)"
echo "View logs in AWS CloudWatch console"

echo ""
echo "🎉 Infrastructure setup complete! The instances are now ready for Docker application deployment."
