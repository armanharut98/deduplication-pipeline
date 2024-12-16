resource "aws_sqs_queue" "event_queue" {
  name                      = "event_queue"
  max_message_size          = 1024
  message_retention_seconds = 86400
  receive_wait_time_seconds = 5


  tags = {
    Name = "event_queue"
  }
}
