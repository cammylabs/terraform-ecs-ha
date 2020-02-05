resource "aws_lambda_event_source_mapping" "sqs-trigger" {
  event_source_arn = "${aws_sqs_queue.sqs_queue_test.arn}"
  function_name    = "${aws_lambda_function.example.arn}"
}

data "aws_lambda_function" "codedeploy_tracker" {
  function_name = "codedeploy-tracker-${var.app_environment}"
}

resource "aws_sns_topic" "slack" {
  name = "${local.cannonical_name}-slack"
}

resource "aws_sns_topic_subscription" "slack_lambda_subscription" {
  topic_arn = aws_sns_topic.slack.arn
  protocol = "lambda"
  endpoint = data.aws_lambda_function.codedeploy_tracker.arn
}