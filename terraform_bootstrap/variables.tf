variable "aws_account_id" {
  description = "Your AWS account ID"
  type        = string
}

variable "client_aws_account_id" {
  description = "Client's AWS account ID"
  type        = string
}

variable "bucket_name" {
  description = "Name of the S3 bucket to create"
  type        = string
  default     = "elcamino_hospitals"
}

variable "failure_notification_email" {
  description = "Email address to notify on Databricks processing failure via SNS."
  type        = string
  default     = "dbx-processing-error@radiantgraph.com"
}
