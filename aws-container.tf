# Local vars
locals {
  file_container_role         = "${path.module}/aws-container-assume-role.json"
  file_container_initial_task = "${path.module}/aws-container-initial-task.json"

  container_policy = {
    "Version": "2012-10-17",
    "Statement": [
      {
        Effect: "Allow",
        Action: [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ],
        Resource: "*"
      },
      {
        Effect: "Allow",
        Action: [
          "logs:PutLogEvents",
          "logs:CreateLogStream"
        ]
        Resource: aws_cloudwatch_log_group.default.arn
      }
    ]
  }

  remote_docker_image = "${aws_ecs_task_definition.initial.family}:${aws_ecs_task_definition.initial.revision}"
}

# Permissions
resource "aws_iam_role" "container" {
  name               = "${local.cannonical_name}-container"
  assume_role_policy = file(local.file_container_role)
}

resource "aws_iam_policy" "container" {
  name   = "${local.cannonical_name}-container"
  policy = jsonencode(local.container_policy)
}

resource "aws_iam_role_policy_attachment" "container" {
  role       = aws_iam_role.container.name
  policy_arn = aws_iam_policy.container.arn
}

# CloudWatch Log Group for the ECS container
resource "aws_cloudwatch_log_group" "container" {
  name = local.cannonical_name
}

# Docker Registry Repository
resource "aws_ecr_repository" "default" {
  name = local.cannonical_name
}

# ECS
resource "aws_ecs_cluster" "default" {
  name = local.cannonical_name
}

resource "aws_ecs_task_definition" "initial" {
  family                   = local.cannonical_name
  container_definitions    = data.template_file.container_initial_task.rendered
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.ecs_cpu
  memory                   = var.ecs_memory
  execution_role_arn       = aws_iam_role.container.arn
  task_role_arn            = aws_iam_role.container.arn
}

resource "aws_ecs_service" "default" {
  name            = local.cannonical_name
  task_definition = local.remote_docker_image
  cluster         = aws_ecs_cluster.default.id
  desired_count   = var.ecs_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    assign_public_ip = true
    security_groups  = [aws_security_group.instances.id]
    subnets          = var.ecs_subnet_ids
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.blue.arn
    container_name   = local.cannonical_name
    container_port   = var.ecs_port
  }

  deployment_controller {
    type = "CODE_DEPLOY"
  }

  depends_on = [
    aws_alb_target_group.blue,
    aws_alb_listener.https,
    aws_alb_listener.http,
    aws_alb.default,
  ]

  lifecycle {
    ignore_changes = [
      task_definition,
      desired_count,
      load_balancer
    ]
  }
}

# CloudWatch Logs
resource "aws_cloudwatch_log_group" "default" {
  name              = local.cannonical_name
  retention_in_days = var.logs_retention_in_days
}

data "template_file" "container_initial_task" {
  template = file(local.file_container_initial_task)

  vars = {
    name = local.cannonical_name
    port = var.ecs_port
  }
}
