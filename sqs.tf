resource "aws_sqs_queue" "guestbook_events" {
  name                       = "guestbook_events"
  visibility_timeout_seconds = 30
  message_retention_seconds  = 345600
}