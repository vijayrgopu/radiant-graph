resource "aws_s3_bucket" "radiant_graph_input" {
  bucket = "radiant-graph-input"
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
    Purpose    = "input"
  }
}
