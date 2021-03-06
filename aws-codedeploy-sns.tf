resource "aws_sns_topic" "slack" {
  name = "${local.cannonical_name}-slack"
}

resource "aws_sns_topic_subscription" "slack_lambda_subscription" {
  topic_arn = aws_sns_topic.slack.arn
  protocol = "lambda"
  endpoint = aws_lambda_function.codedeploy_tracker.arn
}

resource "aws_lambda_permission" "with_sns" {
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.codedeploy_tracker.arn
  principal = "sns.amazonaws.com"
  source_arn = aws_sns_topic.slack.arn
}
