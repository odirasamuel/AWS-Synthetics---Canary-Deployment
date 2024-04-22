terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.17.0"
    }
  }
  # backend "s3" {
  #   bucket         = "infra-sre-us-canary-state-tf-bucket"
  #   dynamodb_table = "infra-sre-us-canary_state_tf_lock"
  #   key            = "state/deltekdev_canary"
  #   encrypt        = true
  #   region         = "us-east-2"
  #   profile        = "canary"
  # }
}


provider "aws" {
  region  = "us-east-2"
  profile = "canary"
}