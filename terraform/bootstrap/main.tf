resource "aws_s3_bucket" "terraform_state" {
  bucket = "ron-zbd-challenge-terraform-state"

  # Best Practice: Block public access
  # This is usually the default now, but explicit is better.
  # The S3 bucket should only be accessed by specific IAM roles.
  # This ensures no one can accidentally make the state file public.
  # This setting is defined in a separate resource on newer AWS providers,
  # but here's the classic S3 bucket resource definition:
}

# Best Practice: Enable Versioning (Crucial for state file recovery)
resource "aws_s3_bucket_versioning" "terraform_state_versioning" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Best Practice: Enable Server-Side Encryption (with KMS for strong security)
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state_encryption" {
  bucket = aws_s3_bucket.terraform_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256" # Use KMS for a more sophisticated approach
    }
  }
}                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           

# Best Practice: Enforce block public access
resource "aws_s3_bucket_public_access_block" "terraform_state_block" {
  bucket = aws_s3_bucket.terraform_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Note: DynamoDB table for state locking removed due to permission constraints
# State locking will be disabled for now