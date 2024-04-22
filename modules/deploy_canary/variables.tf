######################################################################################################################################
############################ VARIABLES WITHOUT DEFAULT VALUES ########################################################################
######################################################################################################################################

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "product" {
  description = "Under what product does the URL belong"
  type        = string
  validation {
    condition     = can(regex("^[a-z]+$", var.product))
    error_message = "`product` must be in lowercase acronym"
  }
}

variable "environment" {
  description = "Name of the environment"
  type        = string
  validation {
    condition     = can(regex("^[a-z]+$", var.environment))
    error_message = "`environment` must be in lowercase acronym. e.g `gccm`, `goss`, `gce`. etc"
  }
}

variable "customer_name" {
  description = "Customer's name canary is developed for"
  type        = string
  validation {
    condition     = can(regex("^[a-z_]+$", var.customer_name))
    error_message = "`customer_name` must be in lowercase words and can only be seperated with underscore, No spacing allowed between words."
  }
}

variable "cluster" {
  description = "Pod environment"
  type        = string
  validation {
    condition     = can(regex("^[A-Z0-9_]+$", var.cluster))
    error_message = "`cluster` can only contain uppercase words, numbers underscore."
  }
}

variable "isVip" {
  description = "If the customer is a VIP"
  type        = bool
}

variable "classification" {
  description = "Classification of the environment"
  type        = string
  validation {
    condition     = contains(["pd", "tt", "dv"], var.classification)
    error_message = "`classification` value is not valid, valid values are: `pd` , `tt` , `dv`."
  }
}

variable "canary_type" {
  description = "Type of URL or API that canary is deployed for. e.g 'login_page'"
  type        = string
  validation {
    condition     = can(regex("^[a-z_]+$", var.canary_type))
    error_message = "`canary_type` name must be in lowercase words and can only be seperated with underscore, No spacing allowed between words."
  }
}

variable "endpoint" {
  description = "Endpoint for SNS topic to send data to"
  type        = string
}

variable "protocol" {
  description = "Protocol to be used with the endpoint"
  type        = string
  validation {
    condition     = contains(["sqs", "sms", "lambda", "firehose", "application", "email", "email-json", "http", "https"], var.protocol)
    error_message = "`protocol` value is not valid, valid values are: `sqs` , `sms` , `lambda` , `firehose` , `application` , `email` , `email-json` , `http` , `https`."
  }
}

variable "unit" {
  description = "The unit for the metric of the synthetic_alarm alarm metric query"
  type        = string
}

variable "stat" {
  description = "The statistics to apply to the metric"
  type        = string
}

variable "period" {
  description = "Granularity of returned data points (in seconds)"
  type        = number
}

variable "namespace" {
  description = "The namespace of the metric for the synthetic alarm"
  type        = string
}

variable "metric_name" {
  description = "Name of the metric"
  type        = string
}

variable "metric_query_id" {
  description = "Metric query id"
  type        = string
  validation {
    condition     = can(regex("^[a-z][a-zA-Z0-9_]*$", var.metric_query_id))
    error_message = "The metric id must start with a lowercase letter and can only contain letters, numbers and underscores."
  }
}

variable "threshold" {
  description = "The value against which the specified statistic is compared. This parameter is required for alarms based on static thresholds, but should not be used for alarms based on anomaly detection models"
  type        = number
}

variable "evaluation_periods" {
  description = "The number of periods over which data is compared to the specified threshold."
  type        = number
}

variable "datapoints_to_alarm" {
  description = "The number of datapoints that must be breaching to trigger the alarm."
  type        = number
}

variable "comparison_operator" {
  description = "The arithmetic operation to use when comparing the specified Statistic and Threshold"
  type        = string
  validation {
    condition     = contains(["GreaterThanOrEqualToThreshold", "GreaterThanThreshold", "LessThanThreshold", "LessThanOrEqualToThreshold"], var.comparison_operator)
    error_message = "`comparison_operator` Statistic value is not valid for static threshold type, valid values are: `GreaterThanOrEqualToThreshold` , `GreaterThanThreshold` , `LessThanThreshold` , `LessThanOrEqualToThreshold`."
  }
}

variable "alarm_description" {
  description = "The description for the alarm."
  type        = string
}

variable "location" {
  description = "URL's location that canary is built for"
  type        = string
}

variable "group" {
  description = "Group the canary belongs to"
  type        = string
}

variable "secret_name" {
  description = "Secret name of the credentials to be used in the canary script, this should be retrieved from AWS SecretManager"
  type        = string
}

######################################################################################################################################
############################### VARIABLES WITH DEFAULT VALUES ########################################################################
######################################################################################################################################

variable "start_canary" {
  description = "Whether to run or stop the canary."
  type        = bool
  default     = true
}

variable "timeout_in_seconds" {
  description = "Canary run-time timeout (in seconds)"
  type        = number
  default     = 600
}

variable "canary_script_name" {
  description = "The name of the canary script file, usually anything before the '*.js'"
  type        = string
  default     = "recordedScript"
}

variable "treat_missing_data" {
  description = "Set how alarm handles missing data points"
  type        = string
  default     = "missing"
  validation {
    condition     = contains(["missing", "ignore", "breaching", "notBreaching"], var.treat_missing_data)
    error_message = "`protocol` value is not valid, valid values are: `missing` , `ignore` , `breaching` , `notBreaching`."
  }
}

variable "failure_retention_period" {
  description = "Number of days to retain data about failed runs of this canary."
  type        = number
  default     = 31
}

variable "success_retention_period" {
  description = "Number of days to retain data about successful runs of this canary."
  type        = number
  default     = 31
}

variable "run_frequency" {
  description = "How often im minute(s) the canary should run"
  type        = number
  default     = 10
}

variable "runtime_version" {
  description = "Runtime version to use for the canary"
  type        = string
  default     = "syn-nodejs-puppeteer-6.0"
}

variable "create_cw_metric_alarm" {
  description = "Decide whether to create the cloudwatch metric alarm for Failed canaries runs because if there's no datapoint for the metric, creating the alarm will fail"
  type        = bool
  default     = false
}

variable "create_canary_group" {
  description = "Decide whether to create a canary group"
  type        = bool
  default     = false
}

variable "create_canary_group_association" {
  description = "Decide whether to add the canary to a group. This should only be set to true if canary group exists (confirm via AWS console) or var.create_canary_group is set to true"
  type        = bool
  default     = false
}