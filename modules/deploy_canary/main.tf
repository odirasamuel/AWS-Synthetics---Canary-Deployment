data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  alarm_description = {
    "description" = "${var.alarm_description}"
    "location"    = "${var.location}"
    "group"       = "${var.group}"
  }

  tags = {
    "classification" = "${var.classification}"
    "environment"    = "${var.environment}"
    "cluster"        = "${var.cluster}"
    "customer"       = "${var.customer_name}"
    "isVIP"          = "${var.isVip}"
  }
}

#Zip the canary script folder
data "archive_file" "zip_canary_script" {
  type        = "zip"
  output_path = "../../zipped_canary_scripts/product/${var.product}/${var.customer_name}_${var.classification}_${var.canary_type}.zip"
  source_dir  = "../../canary_scripts/product/${var.product}/${var.customer_name}_${var.classification}_${var.canary_type}"
}

#S3 bucket to store canary run data
#AWS does not allow uppercase latters in S3 bucket names
resource "aws_s3_bucket" "canary_run_data_bucket" {
  bucket = replace("${var.environment}-${var.customer_name}-${var.classification}-${var.canary_type}-canary-bucket", "_", "-")

  tags = local.tags
}

#SSE configuration
resource "aws_s3_bucket_server_side_encryption_configuration" "canary_run_data_bucket_encrption_configuration" {
  bucket = aws_s3_bucket.canary_run_data_bucket.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

#configuring lifecycle for canary run data
resource "aws_s3_bucket_lifecycle_configuration" "canary_run_data_bucket_lifecycle_configuration" {
  bucket = aws_s3_bucket.canary_run_data_bucket.bucket
  rule {
    id = "config"

    noncurrent_version_expiration {
      noncurrent_days = 90
    }

    status = "Enabled"
  }
}

#Block public access to canary bucket
resource "aws_s3_bucket_public_access_block" "canary_run_data_bucket" {
  bucket = aws_s3_bucket.canary_run_data_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_iam_policy_document" "canary_lambda_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

#IAM role to grant canary lambda function permission
resource "aws_iam_role" "canary_lambda_role" {
  name               = replace("${var.environment}-${var.customer_name}-${var.classification}-${var.canary_type}-canary-role", "_", "-")
  assume_role_policy = data.aws_iam_policy_document.canary_lambda_assume_role_policy.json

  tags = local.tags
}

#cloudwatch logging policy
resource "aws_iam_role_policy" "canary_logging_role_policy" {
  name = replace("${var.environment}-${var.customer_name}-${var.classification}-${var.canary_type}-canary-logging-policy", "_", "-")
  role = aws_iam_role.canary_lambda_role.name
  policy = templatefile("../../policies/cloudwatch_log_group.json", {
    log_group_arn = "*"
  })
}

#s3 bucket access policy
resource "aws_iam_role_policy" "canary_bucket_role_policy" {
  name = replace("${var.environment}-${var.customer_name}-${var.classification}-${var.canary_type}-canary-bucket-policy", "_", "-")
  role = aws_iam_role.canary_lambda_role.name
  policy = templatefile("../../policies/s3.json", {
    canary_bucket_arn = "${aws_s3_bucket.canary_run_data_bucket.arn}"
    buckets_arn       = "arn:aws:s3:::*"
  })
}

#aws xray trace policy
resource "aws_iam_role_policy" "xray_trace_role_policy" {
  name = replace("${var.environment}-${var.customer_name}-${var.classification}-${var.canary_type}-xray-trace-policy", "_", "-")
  role = aws_iam_role.canary_lambda_role.name
  policy = templatefile("../../policies/xray.json", {
    xray_trace = "${aws_s3_bucket.canary_run_data_bucket.arn}"
  })
}

#Cloudwatch synthetics policy
resource "aws_iam_role_policy" "cw_synthetics_role_policy" {
  name = replace("${var.environment}-${var.customer_name}-${var.classification}-${var.canary_type}-cw-synthetics-policy", "_", "-")
  role = aws_iam_role.canary_lambda_role.name
  policy = templatefile("../../policies/cloudwatch_synthetics.json", {
    cw_metrics = "*"
  })
}

#SecretManager policy
resource "aws_iam_role_policy" "secrets_role_policy" {
  name = replace("${var.environment}-${var.customer_name}-${var.classification}-${var.canary_type}-secrets-policy", "_", "-")
  role = aws_iam_role.canary_lambda_role.name
  policy = templatefile("../../policies/secrets.json", {
    secret_arn = "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:${var.secret_name}-*"
  })
}

#sns policy
resource "aws_iam_role_policy" "sns_role_policy" {
  name = replace("${var.environment}-${var.customer_name}-${var.classification}-${var.canary_type}-sns-policy", "_", "-")
  role = aws_iam_role.canary_lambda_role.name
  policy = templatefile("../../policies/lambda_sns.json", {
    sns_arn = "${aws_sns_topic.synthetics_canary_endpoint_topic.arn}"
  })
}

#Canary
resource "aws_synthetics_canary" "canary" {
  name                 = replace("${var.customer_name}-${var.classification}-${var.canary_type}", "_", "-")
  artifact_s3_location = "s3://${aws_s3_bucket.canary_run_data_bucket.bucket}/"
  execution_role_arn   = aws_iam_role.canary_lambda_role.arn
  handler              = "${var.canary_script_name}.handler"
  zip_file             = "../../zipped_canary_scripts/product/${var.product}/${var.customer_name}_${var.classification}_${var.canary_type}.zip"
  runtime_version      = var.runtime_version
  schedule {
    expression = "rate(${var.run_frequency} minutes)"
  }
  success_retention_period = var.success_retention_period
  failure_retention_period = var.failure_retention_period
  artifact_config {
    s3_encryption {
      encryption_mode = "SSE_S3"
    }
  }

  run_config {
    timeout_in_seconds = var.timeout_in_seconds
    environment_variables = {
      REGION      = var.aws_region
      SECRET_NAME = var.secret_name
    }
  }
  start_canary = var.start_canary

  depends_on = [data.archive_file.zip_canary_script]

  tags = local.tags
}

#cloudwatch synthetics alarm
resource "aws_cloudwatch_metric_alarm" "synthetic_alarm" {
  alarm_name          = replace("${var.environment}-${var.customer_name}-${var.classification}-${var.canary_type}-canary-alarm", "_", "-")
  comparison_operator = var.comparison_operator
  evaluation_periods  = var.evaluation_periods
  period              = var.period
  metric_name         = var.metric_name
  namespace           = var.namespace
  statistic           = var.stat
  threshold           = var.threshold
  alarm_description   = jsonencode(local.alarm_description)
  alarm_actions       = ["${aws_sns_topic.synthetics_canary_endpoint_topic.arn}"]
  #   ok_actions          = ["${aws_sns_topic.synthetics_canary_lambda_topic.arn}"]
  treat_missing_data  = var.treat_missing_data
  datapoints_to_alarm = var.datapoints_to_alarm
  unit                = var.unit
  dimensions = {
    "CanaryName" = replace("${var.customer_name}-${var.classification}-${var.canary_type}", "_", "-")
  }

  tags = local.tags
}


#Endpoint SNS topic for alarm notification
resource "aws_sns_topic" "synthetics_canary_endpoint_topic" {
  name            = replace("${var.environment}-${var.customer_name}-${var.classification}-${var.canary_type}-canary-endpoint-topic", "_", "-")
  delivery_policy = <<EOF
  {
    "http": {
      "defaultHealthyRetryPolicy": {
        "minDelayTarget": 20,
        "maxDelayTarget": 20,
        "numRetries": 3,
        "numMaxDelayRetries": 0,
        "numNoDelayRetries": 0,
        "numMinDelayRetries": 0,
        "backoffFunction": "linear"
      },
      "disableSubscriptionOverrides": false,
      "defaultRequestPolicy": {
        "headerContentType": "text/plain; charset=UTF-8"
      }
    }
  }
  EOF

  tags = local.tags
}

#Endpoint SNS topic policy
resource "aws_sns_topic_policy" "synthetics_canary_endpoint_topic_policy" {
  arn = aws_sns_topic.synthetics_canary_endpoint_topic.arn
  policy = templatefile("../../policies/sns.json", {
    sns_arn    = "${aws_sns_topic.synthetics_canary_endpoint_topic.arn}",
    account_id = "${data.aws_caller_identity.current.account_id}"
  })
}

#Endpoint SNS topic subscription
resource "aws_sns_topic_subscription" "synthetics_canary_endpoint_topic_subscription" {
  topic_arn              = aws_sns_topic.synthetics_canary_endpoint_topic.arn
  protocol               = var.protocol
  endpoint               = var.endpoint
  endpoint_auto_confirms = true
}

#Synthetic canary group
resource "aws_synthetics_group" "canary_group" {
  count = var.create_canary_group ? 1 : 0
  name  = var.group

  tags = local.tags
}

#Add canary to group
resource "aws_synthetics_group_association" "canary_group_association" {
  count      = var.create_canary_group_association ? 1 : 0
  group_name = var.create_canary_group ? aws_synthetics_group.canary_group[0].name : var.group
  canary_arn = aws_synthetics_canary.canary.arn
}