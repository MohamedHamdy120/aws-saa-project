resource "aws_sns_topic" "sns_topic" {
  name = "guestbook-notifications"
}

resource "aws_sns_topic_subscription" "sns_email" {
  topic_arn = aws_sns_topic.sns_topic.arn
  protocol  = "email"
  endpoint  = "mohamed.hamdy120@hotmail.com"
}