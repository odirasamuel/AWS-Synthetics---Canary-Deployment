terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.17.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "2.4.0"
    }
  }
  # backend "s3" {
  #   bucket         = "infra-sre-us-canary-state-tf-bucket"
  #   dynamodb_table = "infra-sre-us-canary_state_tf_lock"
  #   key            = "canary/deltekdev_test_canary/modular_test"
  #   encrypt        = true
  #   region         = "us-east-2"
  #   profile        = "canary"
  # }
}