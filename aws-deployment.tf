locals {
  file_codedeploy_role = "${path.module}/aws-deployment-assume-role.json"
  file_codedeploy_policy = "${path.module}/aws-deployment-role-policy.json"

  default_file_container_task = "${path.module}/aws-container-task.json"
  file_container_task = "${
    var.ecs_task_definition == ""
    ? local.default_file_container_task
    : var.ecs_task_definition
  }"

  default_file_container_spec = "${path.module}/aws-container-spec.json"
  file_container_spec = "${
    var.ecs_app_spec == ""
    ? local.default_file_container_spec
    : var.ecs_app_spec
  }"
}

# CodeDeploy Permissions
resource "aws_iam_role" "codedeploy" {
  name = "${local.cannonical_name}-codedeploy"
  assume_role_policy = "${file(local.file_codedeploy_role)}"
}

resource "aws_iam_policy" "codedeploy" {
  name = "${local.cannonical_name}-codedeploy"
  policy = "${file(local.file_codedeploy_policy)}"
}

resource "aws_iam_role_policy_attachment" "codedeploy" {
  role = "${aws_iam_role.codedeploy.name}"
  policy_arn = "${aws_iam_policy.codedeploy.arn}"
}

# Code Deploy
resource "aws_codedeploy_app" "default" {
  compute_platform = "ECS"
  name             = "${local.cannonical_name}"
}

resource "aws_codedeploy_deployment_group" "default" {
  app_name               = "${aws_codedeploy_app.default.name}"
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"
  deployment_group_name  = "${local.cannonical_name}"
  service_role_arn       = "${aws_iam_role.codedeploy.arn}"

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }

    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 1
    }
  }

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  ecs_service {
    cluster_name = "${aws_ecs_cluster.default.name}"
    service_name = "${aws_ecs_service.default.name}"
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = ["${aws_alb_listener.https.arn}"]
      }

      target_group { name = "${aws_alb_target_group.blue.name}" }
      target_group { name = "${aws_alb_target_group.green.name}" }
    }
  }
}

# Uploading new version
data "template_file" "container_task" {
  template = "${file(local.file_container_task)}"

  vars {
    image              = "${aws_ecr_repository.default.repository_url}"
    name               = "${local.cannonical_name}"
    port               = "${var.ecs_port}"
    region             = "${var.aws_region}"
    log-group          = "${aws_cloudwatch_log_group.container.name}"
    family             = "${local.cannonical_name}"
    cpu                = "${var.ecs_cpu}"
    memory             = "${var.ecs_memory}"
    execution_role_arn = "${aws_iam_role.container.arn}"
    task_role_arn      = "${aws_iam_role.container.arn}"
  }
}

data "template_file" "container_spec" {
  template = "${file(local.file_container_spec)}"

  vars {
    image           = "${aws_ecr_repository.default.repository_url}"
    name            = "${local.cannonical_name}"
    port            = "${var.ecs_port}"
    region          = "${var.aws_region}"
    log-group       = "${aws_cloudwatch_log_group.container.name}"
  }
}

data "local_file" "docker_file" {
  filename = "${var.docker_root_path}/Dockerfile"
}

resource "null_resource" "deploy_new_task" {

  triggers {
    docker_image = "${local.cannonical_name}-${var.app_version}"
    docker_file = "${base64sha256(data.local_file.docker_file.content)}"

    task_def = "${base64sha256(data.template_file.container_task.rendered)}"
    profile = "${var.aws_profile}"
    image = "${aws_ecr_repository.default.repository_url}"
    service = "${aws_ecs_service.default.name}"
    cluster = "${aws_ecs_cluster.default.arn}"

    deploy_spec = "${base64sha256(data.template_file.container_spec.rendered)}"
    deploy_app = "${aws_codedeploy_app.default.name}"
    deploy_group = "${aws_codedeploy_deployment_group.default.deployment_group_name}"
  }

  provisioner "local-exec" {
    command = "$DEPLOY $PROFILE $IMAGE $SERVICE $CLUSTER \"$TASK_DEF\" $DOCKER_ROOT $DEPLOY_APP $DEPLOY_GRP \"$DEPLOY_SPEC\""

    environment {
      DEPLOY = "${path.module}/aws-container-deploy.sh"
      PROFILE = "${var.aws_profile}"
      IMAGE = "${aws_ecr_repository.default.repository_url}"
      SERVICE = "${aws_ecs_service.default.name}"
      CLUSTER = "${aws_ecs_cluster.default.arn}"
      TASK_DEF = "${data.template_file.container_task.rendered}"
      DOCKER_ROOT = "${var.docker_root_path}"
      DEPLOY_APP = "${aws_codedeploy_app.default.name}"
      DEPLOY_GRP = "${aws_codedeploy_deployment_group.default.deployment_group_name}"
      DEPLOY_SPEC = "${data.template_file.container_spec.rendered}"
    }
  }

  depends_on = [
    "aws_ecr_repository.default",
    "aws_ecs_cluster.default",
    "aws_ecs_service.default",
    "aws_ecs_task_definition.initial"
  ]
}