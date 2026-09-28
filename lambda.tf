resource "aws_iam_role" "lambda_sns_sqs" {
  name = "lambda-sns-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  name = "lambda_policy"
  role = aws_iam_role.lambda_sns_sqs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes"]
        Resource = aws_sqs_queue.guestbook_events.arn
      },
      {
        Effect   = "Allow"
        Action   = ["sns:Publish"]
        Resource = aws_sns_topic.sns_topic.arn
      },
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "*"
      }
    ]
  })
}

resource "aws_lambda_function" "sqs_processor" {
  function_name    = "sqs_processor"
  runtime          = "python3.11"
  handler          = "lambda_function.lambda_handler"
  role             = aws_iam_role.lambda_sns_sqs.arn
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.sns_topic.arn
    }
  }
}

resource "aws_lambda_event_source_mapping" "source_mapping" {
  event_source_arn = aws_sqs_queue.guestbook_events.arn
  function_name    = aws_lambda_function.sqs_processor.arn
  batch_size       = 1
}