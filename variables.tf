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

variable "vpc_subnet_ids" {
  description = "The network subnets this architecture will be running"
  type        = list(string)
}

variable "route53_zone_id" {
  description = "The Route53's Zone Id in which a Record A will point to the Load Balancer"
}

variable "acm_certificate_arn" {
  description = "The ACM certificate ARN to be used in the ALB's Target Group Listener"
}

variable "ecs_desired_count" {
  description = "The number of instances of the task definition to place and keep running. Defaults"
  default     = 1
}

variable "ecs_friendly_dns" {
  description = "A human friendly DNS entry that will point to the Load Balancer"
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

variable "lb_deregistration_delay" {
  description = "The amount time for ELB to wait before changing the state of a deregistering target from draining to unused"
  default     = 20
}

# Computed global variables
locals {
  cannonical_name = "${var.app_name}-${var.app_environment}"
  deployment_root_path = var.deployment_root_path == "" ? "${var.docker_root_path}/../deployment" : var.deployment_root_path
}

