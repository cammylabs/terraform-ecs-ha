output "ecs_resource_id" {
  description = "The just created ECS resource Id. May be useful to create CloudWatch metrics."
  value       = "service/${aws_ecs_cluster.default.name}/${aws_ecs_service.default.name}"
}
