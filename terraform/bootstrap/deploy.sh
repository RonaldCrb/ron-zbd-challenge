#!/bin/bash

# Bootstrap Deployment Script for Ron ZBD Challenge Infrastructure
# This script creates the S3 bucket for Terraform state and DynamoDB table for state locking
set -e

echo "🚀 Starting bootstrap deployment for Ron ZBD Challenge infrastructure..."

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

echo "✅ Prerequisites check passed"

# Check if resources already exist
echo "🔍 Checking if bootstrap resources already exist..."

# Check if S3 bucket exists
if aws s3 ls "s3://ron-zbd-challenge-terraform-state" 2>/dev/null; then
    echo "⚠️  S3 bucket 'ron-zbd-challenge-terraform-state' already exists"
    BUCKET_EXISTS=true
else
    echo "✅ S3 bucket does not exist - will be created"
    BUCKET_EXISTS=false
fi

# Note: DynamoDB table removed due to permission constraints
TABLE_EXISTS=true  # Skip DynamoDB checks

if [[ "$BUCKET_EXISTS" == "true" ]]; then
    echo "✅ Bootstrap resources already exist. Nothing to deploy."
    exit 0
fi

echo ""
echo "📋 Bootstrap resources to be created:"
echo "   • S3 Bucket: ron-zbd-challenge-terraform-state"
echo "   • Encryption: AES256"
echo "   • Versioning: Enabled"
echo "   • Public Access: Blocked"
echo "   • Note: State locking disabled (DynamoDB permission issue)"
echo ""

# Ask for confirmation
read -p "🤔 Do you want to proceed with the bootstrap deployment? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Bootstrap deployment cancelled."
    exit 1
fi

# Initialize Terraform
echo "🔧 Initializing Terraform..."
terraform init

# Plan the deployment
echo "📋 Planning bootstrap deployment..."
terraform plan

# Ask for final confirmation
echo ""
read -p "🤔 Do you want to apply these changes? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Bootstrap deployment cancelled."
    exit 1
fi

# Apply the configuration
echo "🚀 Deploying bootstrap resources..."
terraform apply -auto-approve

# Display outputs
echo ""
echo "✅ Bootstrap deployment completed successfully!"
echo ""
echo "📊 Bootstrap resources created:"
echo "   • S3 Bucket: ron-zbd-challenge-terraform-state"
echo "   • Note: State locking disabled (no DynamoDB table)"
echo ""

# Display next steps
echo "🎯 Next steps:"
echo "   1. Your Terraform backend is now configured"
echo "   2. You can now deploy the main infrastructure:"
echo "      cd .."
echo "      export PERSONAL_IP=\"YOUR_IP_ADDRESS/32\""
echo "      ./deploy.sh"
echo ""
echo "🎉 Bootstrap setup complete! Ready for main infrastructure deployment."
