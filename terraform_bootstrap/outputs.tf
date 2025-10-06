output "bucket_name" {
  description = "The name of the S3 bucket"
  value       = aws_s3_bucket.client_bucket.id
}

output "client_write_role_arn" {
  description = "ARN of the IAM role for client write access"
  value       = aws_iam_role.client_write_role.arn
}

output "sns_failure_notification_arn" {
  value       = aws_sns_topic.databricks_failure.arn
  description = "SNS Topic ARN for Databricks processing failure notifications."
}
