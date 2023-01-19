variable "project" {
  type        = string
  default     = "demo"
  description = "Name of your project, will be used as a prefix for AWS resources names"
}

variable "environment" {
  type        = string
  default     = "data-qa-dev"
  description = "Additional AWS Resource prefix for all resource name, e.g. project-environment"
}

variable "slack_webhook_url" {
  type        = string
  default     = null
  description = "The Slack webhook url, which will be used to send notification if some errors will be found it datasets"
}

variable "tags" {
  type        = map(string)
  default     = null
  description = "Map of AWS Resource TAG's which will be added to each resource"
}

variable "s3_source_data_bucket" {
  type        = string
  description = "Bucket name, with the data on which test will be executed"
}

variable "test_coverage_path" {
  type        = string
  description = "Path to the tests description path, relative to the root TF"
  default     = "configs/test_coverage.json"
}

variable "pipeline_config_path" {
  type        = string
  description = "Path to the pipeline description path, relative to the root TF"
  default     = "configs/pipeline.json"
}

variable "pks_path" {
  type        = string
  description = "Path to the primary keys description path, relative to the root TF"
  default     = "configs/pks.json"
}

variable "sort_keys_path" {
  type        = string
  description = "Path to the sort keys description path, relative to the root TF"
  default     = "configs/sort_keys.json"
}

variable "mapping_path" {
  type        = string
  description = "Path to the mapping description path, relative to the root TF"
  default     = "configs/mapping.json"
}

variable "expectations_store" {
  type        = string
  description = "Path to the expectations_store directory, relative to the root TF"
  default     = "expectations_store"
}

variable "create_cloudfront" {
  type        = bool
  description = "Create CloudFront distribution"
  default     = true
}

variable "cloudfront_location_restrictions" {
  default     = ["US", "CA", "GB", "DE", "TR"]
  description = "List of regions allowed for CloudFront distribution"
}

variable "lambda_allure_report_memory" {
  description = "Amount of memory allocated to the lambda function lambda_allure_report"
  default     = 1024
}

variable "lambda_fast_data_qa_memory" {
  description = "Amount of memory allocated to the lambda function lambda_fast_data_qa"
  default     = 5048
}

variable "lambda_push_report_memory" {
  description = "Amount of memory allocated to the lambda function lambda_push_report"
  default     = 1024
}

variable "lambda_push_jira_url" {
  type        = string
  default     = null
  description = "Lambda function push report env variable JIRA_URL"
}

variable "lambda_push_secret_name" {
  type        = string
  default     = null
  description = "Lambda function push report env variable JIRA_URL"
}

variable "redshift_db_name" {
  type        = string
  default     = null
  description = "db name for redshift"
}

variable "redshift_secret" {
  type        = string
  default     = null
  description = "secret name from Secret Manager for Redshift cluster"
}

variable "push_report_extra_vars" {
  type        = map(string)
  default     = {}
  description = "Extra variables for push report lambda"
}

variable "cloudfront_distribution_enabled" {
  type        = bool
  default     = true
  description = "Enable CloudFront distribution"
}

variable "cloudfront_additional_cache_behaviors" {
  type = list(object({
    path_pattern     = string
    allowed_methods  = list(string)
    cached_methods   = list(string)
    target_origin_id = optional(string)
    forwarded_values = object({
      query_string = bool
      cookies = object({
        forward = string
      })
    })
    lambda_function_associations = list(object({
      event_type = string
      lambda_arn = string
    }))
    viewer_protocol_policy = string
    min_ttl                = number
    default_ttl            = number
    max_ttl                = number
    compress               = bool
  }))
  default = []
}

variable "certificate_arn" {
  type        = string
  default     = null
  description = "ARN of the certificate for CloudFront distribution"
}

variable "cloudfront_cnames" {
  type        = list(string)
  default     = []
  description = "List of CNAMEs for CloudFront distribution"
}
