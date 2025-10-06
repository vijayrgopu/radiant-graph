resource "aws_s3_bucket" "radiant_graph_input_failed" {
  bucket = "radiant-graph-input-failed"
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
    Purpose    = "failed"
  }
}
