# General use variables
variable "app_name" {
  description = "An identifier for this project. It should be unique once it will be used as prefix for AWS resources"
}

variable "app_version" {
  description = "A unique version identifier for the application that will be deployed"
}

variable "app_environment" {
  description = "An identifier for the environment this project is running on. (e.g.: production, staging, etc)"
  default     = "staging"
}

variable "datadog_api_key" {
  description = "DataDog API KEY. https://docs.datadoghq.com/agent/docker/?tab=standard"
}

variable "docker_app_name" {
  description = "The 'app_name' to be used inside the Docker image. If not defined, 'app_name' will be used."
  default = ""
}

variable "docker_root_path" {
  description = "The root folder to generate the Docker image. Usually the place where Dockerfile is located"
}

variable "docker_parent_image" {
  description = "The parent image used as base for your deployment. [Optional]"
  default = ""
}

variable "deployment_root_path" {
  description = "The folder that will contain all resources required to perform a release deployment"
  default = ""
}

# Resource Related Variables
variable "aws_profile" {
  description = "The Amazon profile which contains enough permission to perform this deployment"
  default = "default"
}

variable "aws_region" {
  description = "The Amazon Region your application will be running"
}

variable "vpc_id" {
  description = "The VPC Id the AWS resources will be attached to"
}

variable "route53_zone_id" {
  description = "The Route53's Zone Id in which a Record A will point to the Load Balancer"
}

variable "route53_root_domain" {
  description = "The root domain in which a human-readable DNS entry that will be created and point to the Load Balancer"
}

variable "route53_record_name" {
  description = "Record name to be used along with the 'route53_root_domain'"
  default = ""
}

variable "acm_certificate_arn" {
  description = "The ACM certificate ARN to be used in the ALB's Target Group Listener"
}

variable "logs_retention_in_days" {
  description = "How long should the log be retained"
  default = 1
}

variable "ecs_desired_count" {
  description = "The number of instances of the task definition to place and keep running. Defaults"
  default     = 1
}

variable "ecs_port" {
  description = "The TCP/HTTP(S) port which the software is exposed inside the container"
  default     = 8080
}

variable "ecs_protocol" {
  description = "The protocol which the software is exposed. [HTTP/HTTPS]"
  default     = "HTTP"
}

variable "ecs_cpu" {
  description = "Fargate instance CPU units to provision (1 vCPU = 1024 CPU units)"
  default     = "256"
}

variable "ecs_memory" {
  description = "Fargate instance memory to provision (in MiB)"
  default     = "512"
}

variable "ecs_task_definition" {
  description = "ECS Fargate task definition file. If defined it will overwrite other ecs_* values."
  default     = ""
}

variable "ecs_app_spec" {
  description = "The CodeDeploy AppSpec file. If defined it will overwrite other ecs_* values."
  default     = ""
}

variable "ecs_subnet_ids" {
  description = "The network subnets in which ECS task will be running"
  type        = list(string)
}

variable "lb_health_check_path" {
  description = "The destination for the health check request"
  default     = "/health-check"
}

variable "lb_health_check_interval" {
  description = "The approximate amount of time, in seconds, between health checks of an individual target"
  default     = 5
}

variable "lb_health_check_timeout" {
  description = "The amount of time, in seconds, during which no response means a failed health check."
  default     = 2
}

variable "lb_health_check_threshold" {
  description = "The number of consecutive health checks successes required before considering an unhealthy target healthy."
  default     = 3
}

variable "lb_health_failure_check_threshold" {
  default     = 10
}

variable "lb_deregistration_delay" {
  description = "The amount time for ELB to wait before changing the state of a deregistering target from draining to unused"
  default     = 20
}

variable "lb_subnet_ids" {
  description = "The network subnets in which Load Balancer will be running"
  type        = list(string)
}

variable "lb_slow_start" {
  description = "The amount time for targets to warm up before the load balancer sends them a full share of requests. The range is 30-900 seconds or 0 to disable. The default value is 0 seconds."
  default = 0
}

variable "datadog-extra-config" {
  default = "do_something.sh; ./init"
}

variable "slack_webhook_codedeploy" {
  description = "Slack channel webhook. Codedeploy messages are going to be forwarded and posted there."
  default = "https://hooks.slack.com/services/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"
}

variable "datadog_environment_tag" {
  description = "Helps to sort out logs in datadoghq. Example: develop"
  default = ""
}

variable "datadog_region_tag" {
  description = "Helps to sort out logs in datadoghq, Example: au"
  default = ""
}

# Auth0 Variables (optional, use only when required)
variable "auth0_authorization_endpoint" { default = "" }
variable "auth0_client_id" { default = "" }
variable "auth0_client_secret" { default = "" }
variable "auth0_issuer" { default = "" }
variable "auth0_token_endpoint" { default = "" }
variable "auth0_user_info_endpoint" { default = "" }

# Computed global variables
locals {
  docker_app_name = var.docker_app_name == "" ? var.app_name : var.docker_app_name
  using_auth0 = var.auth0_client_id != ""
  cannonical_name = "${var.app_name}-${var.app_environment}"
  route53_record = var.route53_record_name == "" ? local.cannonical_name : var.route53_record_name
  deployment_root_path = var.deployment_root_path == "" ? "${var.docker_root_path}/../deployment" : var.deployment_root_path
  app_tags = {
    app_name        = var.app_name
    app_environment = var.app_environment
  }
  lambdas_dir = "${path.module}/lambdas"
  output_dir = "${path.module}/dist"

  datadog-ecs-name = "${var.app_name}-datadog-ecs-service-${var.app_environment}"

  datadog_environment_tag = var.datadog_environment_tag == "" ? var.app_name : var.datadog_environment_tag
  datadog_region_tag = var.datadog_region_tag == "" ? var.app_environment : var.datadog_region_tag

}
