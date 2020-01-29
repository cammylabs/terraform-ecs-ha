resource "aws_ecs_task_definition" "datadog_definiton" {
  family = "${var.docker_app_name}-datadog-task-${var.app_environment}-1"

  task_role_arn = data.aws_iam_role.ecs-datadog-role.arn

  container_definitions = <<EOF
    [
      {
        "name": "${var.docker_app_name}-datalog-agent",
        "image": "datadog/agent:latest",

        "cpu": 10,
        "memory": 256,
        "environment": [{
          "name" : "DD_API_KEY",
          "value" : "${var.datadog_api_key}"
        },
        {
          "name" : "API_KEY",
          "value" : "${var.datadog_api_key}"
        }],
        "mountPoints": [{
        "sourceVolume": "docker-sock",
        "containerPath": "/var/run/docker.sock",
        "readOnly": false
      },{
        "sourceVolume": "proc",
        "containerPath": "/host/proc",
        "readOnly": true
      },{
        "sourceVolume": "cgroup",
        "containerPath": "/host/sys/fs/cgroup",
        "readOnly": true
      }]
    }
]
EOF

  volume {
    name      = "docker-sock"
    host_path = "/var/run/docker.sock"
  }

  volume {
    name      = "proc"
    host_path = "/proc/"
  }

  volume {
    name      = "cgroup"
    host_path = "/cgroup/"
  }
}


resource "aws_ecs_service" "datadog" {
  name            = local.datadog-ecs-name
  cluster         = aws_ecs_cluster.default.arn
  task_definition = aws_ecs_task_definition.datadog_definiton.arn
  desired_count = 1

  scheduling_strategy = "DAEMON"
}

data "aws_iam_role" "ecs-datadog-role"  {
  name = "${var.app_environment}-ecs-datadog-role"
}

