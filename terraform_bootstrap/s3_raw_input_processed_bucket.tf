resource "aws_s3_bucket" "radiant_graph_input_processed" {
  bucket = "radiant-graph-delta-table"
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
    Purpose    = "processed"
  }
}
