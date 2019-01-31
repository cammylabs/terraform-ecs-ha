# General use variables
variable "app_name" {
  description = "An identifier for this project. It should be unique once it will be used as prefix for AWS resources"
}

variable "app_version" {
  description = "A unique version identifier for the application that will be deployed"
}

variable "app_environment" {
  description = "An identifier for the environment this project is running on. (e.g.: production, staging, etc)"
  default = "staging"
}

variable "docker_root_path" {
  description = "The root folder to generate the Docker image. Usually the place where Dockerfile is located"
}

# Resource Related Variables
variable "aws_profile" {
  description = "The Amazon profile which contains enough permission to perform this deployment"
}

variable "aws_region" {
  description = "The Amazon Region your application will be running"
}

variable "vpc_id"                 {
  description = "The VPC Id to be used during the "
}

variable "vpc_subnet_ids" {
  description = "The network subnets this architecture will be running"
  type = "list"
}

variable "route53_zone_id" {
  description = "The Route53's Zone Id in which a Record A will point to the Load Balancer"
}

variable "acm_certificate_arn" {
  description = "The ACM certificate ARN to be used in the ALB's Target Group Listener"
}

variable "ecs_friendly_dns" {
  description = "A human friendly DNS entry that will point to the Load Balancer"
}

variable "ecs_port" {
  description = "The TCP/HTTP(S) port which the software is exposed inside the container"
  default = 8080
}

variable "ecs_protocol" {
  description = "The protocol which the software is exposed. [HTTP/HTTPS]"
  default = "HTTP"
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
  default = ""
}

variable "ecs_app_spec" {
  description = "The CodeDeploy AppSpec file. If defined it will overwrite other ecs_* values."
  default = ""
}

# Computed global variables
locals {
  cannonical_name = "${var.app_name}-${var.app_environment}"
}