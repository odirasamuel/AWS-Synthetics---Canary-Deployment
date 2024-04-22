resource "aws_s3_bucket" "canary_state_tf_bucket" {
  bucket = "infra-sre-us-canary-state-tf-bucket"
}

resource "aws_s3_bucket_versioning" "canary_state_tf_bucket_versioning" {
  bucket = aws_s3_bucket.canary_state_tf_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_kms_key" "canary_state_tf_bucket_key" {
}

resource "aws_s3_bucket_server_side_encryption_configuration" "canary_state_tf_bucket_encryption" {
  bucket = aws_s3_bucket.canary_state_tf_bucket.bucket
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.canary_state_tf_bucket_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "canary_state_tf_bucket_access" {
  bucket                  = aws_s3_bucket.canary_state_tf_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
