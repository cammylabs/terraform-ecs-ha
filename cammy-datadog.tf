locals {
  lambda_datadog_name = "${local.cannonical_name}-datadog-logs"
  ecs_datadog_name = "${local.cannonical_name}-datadog-fargate"

  datadog_tags = "environment:${var.datadog_environment_tag}, region:${var.datadog_region_tag}"

  lambda_datadog_policy = {
    Version: "2012-10-17",
    Statement: [
      {
        Effect: "Allow",
        Action: "ssm:GetParameter",
        Resource: "arn:aws:ssm:${var.aws_region}:${local.account_id}:parameter/global/DD_API_KEY"
      },
      {
        Effect: "Allow",
        Action: "kms:Decrypt",
        Resource: data.aws_kms_key.parameter_store.arn
      },
      {
        Action: "logs:*",
        Resource: aws_cloudwatch_log_group.datadog_logs.arn,
        Effect: "Allow"
      }
    ]
  }

  iam_lambda_role = {
    Version: "2012-10-17",
    Statement: [
      {
        Action: "sts:AssumeRole",
        Principal: {
          Service: "lambda.amazonaws.com"
        },
        Effect: "Allow",
        Sid: ""
      }
    ]
  }
}


# Compress the file
data "archive_file" "datadog_logs" {
  type = "zip"
  source_dir = "${local.lambdas_dir}/cloudwatch-to-datadog"
  output_path = "${local.output_dir}/cloudwatch-to-datadog.zip"
}

# Lambda Function
resource "aws_lambda_function" "datadog_logs" {
  function_name = local.lambda_datadog_name
  role = aws_iam_role.datadog_logs.arn
  handler = "main.datadog_forwarder"
  description = "Send log streams from Cloudwatch to Datadog"

  filename = data.archive_file.datadog_logs.output_path
  source_code_hash = data.archive_file.datadog_logs.output_base64sha256

  runtime = "python3.7"

  environment {
    variables = {
      DD_TAGS = local.datadog_tags
    }
  }
}

resource "aws_lambda_permission" "datalog_logs" {
  statement_id  = "${local.cannonical_name}-logs-to-datadog-lambda"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.datadog_logs.function_name
  principal     = "logs.amazonaws.com"
  source_arn    = aws_cloudwatch_log_group.default.arn
}

resource "aws_cloudwatch_log_subscription_filter" "datalog_logs" {
  name            = aws_lambda_function.datadog_logs.function_name
  log_group_name  = aws_cloudwatch_log_group.default.name
  filter_pattern  = ""
  destination_arn = aws_lambda_function.datadog_logs.arn
  depends_on = [aws_lambda_permission.datalog_logs]
}


# CloudWatch Logs
resource "aws_cloudwatch_log_group" "datadog_logs" {
  name              = "/aws/lambda/${aws_lambda_function.datadog_logs.function_name}"
  retention_in_days = 1
}

# Permissions
resource "aws_iam_role" "datadog_logs" {
  name = local.lambda_datadog_name
  assume_role_policy = jsonencode(local.iam_lambda_role)
}

resource "aws_iam_policy" "datadog_logs" {
  name = local.lambda_datadog_name
  path = "/"
  policy = jsonencode(local.lambda_datadog_policy)
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role = aws_iam_role.datadog_logs.name
  policy_arn = aws_iam_policy.datadog_logs.arn
}

data "aws_kms_key" "parameter_store" {
  key_id = "alias/parameter_store_key"
}
