# Local vars
locals {
  file_autoscaling_role   = "${path.module}/aws-autoscaling-assume-role.json"
  file_autoscaling_policy = "${path.module}/aws-autoscaling-role-policy.json"
}

# Auto Scaling Permissions
resource "aws_iam_role" "autoscaling" {
  name               = "${local.cannonical_name}-autoscaling"
  assume_role_policy = file(local.file_autoscaling_role)
}

resource "aws_iam_policy" "autoscaling" {
  name   = "${local.cannonical_name}-autoscaling"
  policy = file(local.file_autoscaling_policy)
}

resource "aws_iam_role_policy_attachment" "autoscaling" {
  role       = aws_iam_role.autoscaling.name
  policy_arn = aws_iam_policy.autoscaling.arn
}

# Auto Scaling
resource "aws_appautoscaling_target" "target" {
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.default.name}/${aws_ecs_service.default.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  role_arn           = aws_iam_role.autoscaling.arn
  min_capacity       = 1
  max_capacity       = 4
}

resource "aws_appautoscaling_policy" "scale_up" {
  name = "${local.cannonical_name}-scale-up"

  resource_id        = aws_appautoscaling_target.target.resource_id
  scalable_dimension = aws_appautoscaling_target.target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.target.service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Maximum"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 1
    }
  }

  depends_on = [aws_appautoscaling_target.target]
}

resource "aws_appautoscaling_policy" "scale_down" {
  name = "${local.cannonical_name}-scale-down"

  resource_id        = aws_appautoscaling_target.target.resource_id
  scalable_dimension = aws_appautoscaling_target.target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.target.service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Maximum"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = -1
    }
  }

  depends_on = [aws_appautoscaling_target.target]
}

# metric used for auto scale
resource "aws_cloudwatch_metric_alarm" "service_cpu_high" {
  alarm_name          = "${local.cannonical_name}-cpu-high-utilization"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Average"
  threshold           = "85"

  dimensions = {
    ClusterName = aws_ecs_cluster.default.name
    ServiceName = aws_ecs_service.default.name
  }

  alarm_actions = [aws_appautoscaling_policy.scale_up.arn]
  ok_actions    = [aws_appautoscaling_policy.scale_down.arn]
}
