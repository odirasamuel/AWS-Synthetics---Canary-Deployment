resource "aws_dynamodb_table" "canary_state_tf_lock" {
  name             = "infra-sre-us-canary_state_tf_lock"
  hash_key         = "LockID"
  billing_mode     = "PAY_PER_REQUEST"
  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  attribute {
    name = "LockID"
    type = "S"
  }

  #   replica {
  #     region_name = "us-east-1"
  #   }

  #   replica {
  #     region_name = "us-west-2"
  #   }

  tags = {}
}
