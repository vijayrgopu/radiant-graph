resource "aws_lambda_function" "trigger_databricks_job" {
  filename         = "trigger_dbx_input_processing.zip" # Package this Python file as a zip
  function_name    = "trigger_databricks_job"
  role             = aws_iam_role.lambda_trigger_databricks.arn
  handler          = "trigger_dbx_input_processing.lambda_handler"
  runtime          = "python3.9"
  timeout          = 60
  environment {
    variables = {
      DATABRICKS_INSTANCE = var.databricks_instance
      DATABRICKS_TOKEN    = var.databricks_token
      DATABRICKS_JOB_ID   = var.databricks_job_id
    }
  }
}

resource "aws_iam_role" "lambda_trigger_databricks" {
  name = "trigger_dbx_input_processing_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "trigger_dbx_input_processing_policy" {
  name = "trigger_dbx_input_processing_policy"
  role = aws_iam_role.lambda_trigger_databricks.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject"
        ]
        Resource = [
          "arn:aws:s3:::radiant-graph-input/*"
        ]
      }
    ]
  })
}

resource "aws_lambda_permission" "allow_s3_invoke" {
  statement_id  = "AllowExecutionFromS3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.trigger_databricks_job.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.radiant_graph_input.arn
}

resource "aws_s3_bucket_notification" "input_bucket_lambda" {
  bucket = aws_s3_bucket.radiant_graph_input.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.trigger_databricks_job.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = ""
    filter_suffix       = ""
  }
  depends_on = [aws_lambda_permission.allow_s3_invoke]
}
