resource "aws_dynamodb_table" "event_table" {
  name             = "event_table"
  billing_mode     = "PROVISIONED"
  read_capacity    = 10
  write_capacity   = 10
  hash_key         = "event_id"
  stream_enabled   = true
  stream_view_type = "NEW_IMAGE"

  attribute {
    name = "event_id"
    type = "S"
  }

  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  tags = {
    Name = "event_table"
  }
}
