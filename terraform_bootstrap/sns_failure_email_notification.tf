resource "aws_sns_topic" "databricks_failure" {
  name = "databricks-failure-notification"
}

resource "aws_sns_topic_subscription" "failure_email" {
  topic_arn = aws_sns_topic.databricks_failure.arn
  protocol  = "email"
  endpoint  = var.failure_notification_email # Set this variable to the notification email address
}

output "sns_topic_arn" {
  value = aws_sns_topic.databricks_failure.arn
  description = "SNS Topic ARN for Databricks failure notifications"
}
