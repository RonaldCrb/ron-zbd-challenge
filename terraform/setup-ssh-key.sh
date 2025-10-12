#!/bin/bash

# SSH Key Pair Setup Script for Ron ZBD Challenge
set -e

echo "🔑 Setting up SSH Key Pair for Ron ZBD Challenge..."

# Check if AWS CLI is configured
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS CLI is not configured or credentials are invalid."
    echo "Please run 'aws configure' first."
    exit 1
fi

KEY_NAME="ron-zbd-challenge-key"
KEY_FILE="$HOME/.ssh/${KEY_NAME}.pem"

echo "📋 SSH Key Pair Configuration:"
echo "   • Key Name: $KEY_NAME"
echo "   • Local File: $KEY_FILE"
echo ""

# Check if key pair already exists in AWS
if aws ec2 describe-key-pairs --key-names "$KEY_NAME" &> /dev/null; then
    echo "✅ Key pair '$KEY_NAME' already exists in AWS."
    
    # Check if local private key exists
    if [[ -f "$KEY_FILE" ]]; then
        echo "✅ Private key file exists locally: $KEY_FILE"
        echo ""
        echo "🎯 You can now deploy your infrastructure with this key pair."
        echo ""
        echo "📝 To connect to your instances after deployment:"
        echo "   chmod 400 $KEY_FILE"
        echo "   ssh -i $KEY_FILE ec2-user@<instance-public-ip>"
        echo ""
        exit 0
    else
        echo "⚠️  Key pair exists in AWS but private key file is missing locally."
        echo "   You'll need to either:"
        echo "   1. Find your private key file"
        echo "   2. Delete and recreate the key pair"
        echo ""
        read -p "🤔 Do you want to delete and recreate the key pair? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "❌ Setup cancelled. Please find your private key or manually create a new key pair."
            exit 1
        fi
        
        echo "🗑️  Deleting existing key pair..."
        aws ec2 delete-key-pair --key-name "$KEY_NAME"
    fi
fi

# Create SSH key pair
echo "🔧 Creating new SSH key pair..."

# Ensure .ssh directory exists
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

# Create the key pair
aws ec2 create-key-pair --key-name "$KEY_NAME" --query 'KeyMaterial' --output text > "$KEY_FILE"

# Set proper permissions
chmod 400 "$KEY_FILE"

echo "✅ SSH key pair created successfully!"
echo ""
echo "📁 Files created:"
echo "   • AWS Key Pair: $KEY_NAME"
echo "   • Private Key: $KEY_FILE"
echo ""
echo "🔐 Security Note:"
echo "   • Keep your private key secure and never share it"
echo "   • The private key file has been set to read-only (400)"
echo ""
echo "🎯 Next Steps:"
echo "   1. Deploy your infrastructure with:"
echo "      export PERSONAL_IP=\"YOUR_IP_ADDRESS\""
echo "      export SSH_KEY_NAME=\"$KEY_NAME\""
echo "      ./deploy.sh"
echo ""
echo "   2. Connect to your instances:"
echo "      ssh -i $KEY_FILE ec2-user@<instance-public-ip>"
echo ""
echo "🎉 SSH key setup complete!"
