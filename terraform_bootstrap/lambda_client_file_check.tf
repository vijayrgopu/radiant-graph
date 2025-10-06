resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda_exec_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  name = "lambda_policy"
  role = aws_iam_role.lambda_exec_role.id
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
          "${aws_s3_bucket.client_bucket.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_lambda_function" "s3_ingest_logger" {
  filename         = "${path.module}/client_metrics_logger.zip"
  function_name    = "s3_ingest_logger"
  role             = aws_iam_role.lambda_exec_role.arn
  handler          = "client_metrics_logger.lambda_handler"
  runtime          = "python3.9"
  source_code_hash = filebase64sha256("${path.module}/client_metrics_logger.zip")
  timeout          = 60
  environment {
    variables = {
      BUCKET_NAME = aws_s3_bucket.client_bucket.bucket
    }
  }
}

resource "aws_s3_bucket_notification" "bucket_notify_lambda" {
  bucket = aws_s3_bucket.client_bucket.id
  lambda_function {
    lambda_function_arn = aws_lambda_function.s3_ingest_logger.arn
    events              = ["s3:ObjectCreated:Put"]
  }
  depends_on = [aws_lambda_function.s3_ingest_logger]
}
