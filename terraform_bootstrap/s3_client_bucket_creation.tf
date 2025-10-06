resource "aws_iam_role" "client_write_role" {
  name = "client-write-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.client_aws_account_id}:root"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "client_write_policy" {
  name = "client-write-policy"
  role = aws_iam_role.client_write_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl"
        ]
        Resource = [
          "${aws_s3_bucket.client_bucket.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_s3_bucket_policy" "restrict_access" {
  bucket = aws_s3_bucket.client_bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = { AWS = "arn:aws:iam::${var.aws_account_id}:root" }
        Action = "s3:*"
        Resource = [
          "${aws_s3_bucket.client_bucket.arn}",
          "${aws_s3_bucket.client_bucket.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Principal = { AWS = "arn:aws:iam::${var.client_aws_account_id}:role/client-write-role" }
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl"
        ]
        Resource = [
          "${aws_s3_bucket.client_bucket.arn}/*"
        ]
      },
      {
        Effect = "Deny"
        Principal = "*"
        Action = "s3:*"
        Resource = [
          "${aws_s3_bucket.client_bucket.arn}",
          "${aws_s3_bucket.client_bucket.arn}/*"
        ]
        Condition = {
          Bool = { "aws:SecureTransport": false }
        }
      }
    ]
  })
}

resource "aws_s3_bucket_logging" "client_bucket_logging" {
  bucket        = aws_s3_bucket.client_bucket.id
  target_bucket = aws_s3_bucket.client_bucket.id
  target_prefix = "log/"
}
resource "aws_s3_bucket" "client_bucket" {
  bucket = var.bucket_name
  acl    = "private"
  versioning {
    enabled = true
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
  tags = {
    Compliance = "HIPAA,SOC2"
  }
}
