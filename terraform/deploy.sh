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

# Check if personal IP is provided via environment variable
if [[ -z "${PERSONAL_IP}" ]]; then
    echo "⚠️  PERSONAL_IP environment variable is not set!"
    echo "   Please set your personal IP address as an environment variable:"
    echo "   export PERSONAL_IP=\"YOUR_IP_ADDRESS\""
    echo ""
    echo "   You can get your IP address by visiting: https://whatismyipaddress.com/"
    echo "   Example: export PERSONAL_IP=\"203.0.113.1\""
    echo ""
    read -p "Enter your IP address (e.g., 203.0.113.1): " ip_input
    if [[ -z "$ip_input" ]]; then
        echo "❌ No IP address provided. Exiting."
        exit 1
    fi
    export PERSONAL_IP="$ip_input"
fi

# Ensure IP has /32 CIDR notation
if [[ "$PERSONAL_IP" != *"/"* ]]; then
    PERSONAL_IP="${PERSONAL_IP}/32"
fi

echo "✅ Using personal IP: $PERSONAL_IP"

# Check if SSH key name is provided via environment variable
if [[ -z "${SSH_KEY_NAME}" ]]; then
    SSH_KEY_NAME="ron-zbd-challenge-key"
    echo "⚠️  SSH_KEY_NAME environment variable is not set!"
    echo "   Using default key name: $SSH_KEY_NAME"
    echo "   To use a different key, set: export SSH_KEY_NAME=\"your-key-name\""
else
    echo "✅ Using SSH key: $SSH_KEY_NAME"
fi

# Select environment
echo ""
echo "🌍 Select deployment environment:"
echo "   1) dev"
echo "   2) prod"
echo ""
read -p "Enter your choice (1 or 2): " env_choice

case $env_choice in
    1)
        ENVIRONMENT="dev"
        ;;
    2)
        ENVIRONMENT="prod"
        ;;
    *)
        echo "❌ Invalid choice. Please select 1 for dev or 2 for prod."
        exit 1
        ;;
esac

echo "✅ Selected environment: $ENVIRONMENT"
echo "✅ Prerequisites check passed"

# Change to environment directory
ENV_DIR="environments/$ENVIRONMENT"
if [[ ! -d "$ENV_DIR" ]]; then
    echo "❌ Environment directory '$ENV_DIR' not found!"
    exit 1
fi

echo "📁 Deploying from: $ENV_DIR"
cd "$ENV_DIR"

# Initialize Terraform
echo "🔧 Initializing Terraform..."
terraform init

# Plan the deployment
echo "📋 Planning deployment for $ENVIRONMENT environment..."
terraform plan -var="personal_ip=$PERSONAL_IP" -var="ssh_key_name=$SSH_KEY_NAME"

# Ask for confirmation
echo ""
read -p "🤔 Do you want to proceed with the $ENVIRONMENT deployment? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Deployment cancelled."
    exit 1
fi

# Apply the configuration
echo "🚀 Deploying $ENVIRONMENT infrastructure..."
terraform apply -auto-approve -var="personal_ip=$PERSONAL_IP" -var="ssh_key_name=$SSH_KEY_NAME"

# Display outputs
echo ""
echo "✅ $ENVIRONMENT deployment completed successfully!"
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
echo "🎉 $ENVIRONMENT infrastructure setup complete! The instances are now ready for Docker application deployment."