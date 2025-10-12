# Bootstrap Infrastructure

This directory contains the Terraform configuration for creating the foundational AWS resources required for the main infrastructure deployment.

## Purpose

The bootstrap resources provide:

1. **S3 Bucket** for storing Terraform state files
2. **Security configurations** including encryption and access controls
3. **Note**: State locking is disabled due to DynamoDB permission constraints

## Resources Created

### S3 Bucket: `ron-zbd-challenge-terraform-state`
- **Versioning**: Enabled for state file recovery
- **Encryption**: AES256 server-side encryption
- **Public Access**: Blocked for security
- **Purpose**: Stores Terraform state files for all environments

### State Locking
- **Status**: Disabled due to DynamoDB permission constraints
- **Note**: Terraform operations should be run sequentially to avoid conflicts

## Usage

### Prerequisites
- AWS CLI configured with appropriate permissions
- Terraform installed

### Deploy Bootstrap Resources

```bash
cd terraform/bootstrap
./deploy.sh
```

The script will:
1. Check if resources already exist
2. Initialize Terraform
3. Plan the deployment
4. Apply the configuration
5. Display next steps

### Required AWS Permissions

The AWS credentials need permissions for:
- S3: `s3:CreateBucket`, `s3:PutBucketVersioning`, `s3:PutBucketEncryption`, `s3:PutBucketPublicAccessBlock`

## After Bootstrap

Once the bootstrap resources are created, you can deploy the main infrastructure:

```bash
cd ..
export PERSONAL_IP="YOUR_IP_ADDRESS/32"
./deploy.sh
```

## Cleanup

To remove bootstrap resources:

```bash
cd terraform/bootstrap
terraform destroy
```

**Warning**: This will delete the S3 bucket. Make sure no Terraform state files are stored in the bucket before destroying.
