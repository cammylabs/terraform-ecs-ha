locals {

  lambda_codedeploy_name = "${local.cannonical_name}-codededploy-deployment-tracker"
  lambda_codedeploy_policy = {

    Version: "2012-10-17",
    Statement: [
      {
        Action:  "sts:AssumeRole",
        Principal: {
          Service: "lambda.amazonaws.com"
        },
        Effect: "Allow",
        Sid: ""
      }
    ]
  }

  codedeploy_lambda_role = {
    Version: "2012-10-17",
    Statement: [
      {
        Action: [
          "logs:*",
          "cloudwatch:*"
        ],
        Effect: "Allow",
        Resource: "*",
        Sid: ""
      }
    ]
  }

}

data "archive_file" "codedeploy_tracker" {
  type = "zip"
  source_dir = "${local.lambdas_dir}/codedeploy-tracker"
  output_path = "${local.output_dir}/codededploy-tracker.zip"
}


resource "aws_lambda_function" "codedeploy_tracker" {

  function_name = "${local.cannonical_name}-codedeploy-tracker"
  role = aws_iam_role.codedeploy_tracker.arn
  handler = "main.handler"
  description = "SNS Client that post CodeDeploy status to Slack"

  filename = data.archive_file.codedeploy_tracker.output_path
  source_code_hash = data.archive_file.codedeploy_tracker.output_base64sha256

  runtime = "python3.7"

  environment {
    variables = {
      SLACK_WEBHOOK = var.slack_webhook_codedeploy
    }
  }

}

resource "aws_iam_role" "codedeploy_tracker" {
  name = local.lambda_codedeploy_name
  assume_role_policy = jsonencode(local.lambda_codedeploy_policy)
}

resource "aws_iam_policy" "codedeploy_tracker" {
  name = "${local.cannonical_name}-lambda_codedeploy_name"

  policy = jsonencode(local.codedeploy_lambda_role)
}

resource "aws_iam_role_policy_attachment" "codedeploy_lambda" {
  role = aws_iam_role.codedeploy_tracker.name
  policy_arn = aws_iam_policy.codedeploy_tracker.arn
}

resource "aws_sns_topic" "sns_slack_tracker" {
  name = "${local.cannonical_name}-slack-codedeploy-sns-topic"
}

resource "aws_sns_topic_subscription" "sns_subscription" {
  endpoint = aws_lambda_function.codedeploy_tracker.arn
  protocol = "lambda"
  topic_arn = aws_sns_topic.sns_slack_tracker.arn

}
