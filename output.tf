output "ecs_resource_id" {
  description = "The just created ECS resource Id. May be useful to create CloudWatch metrics."
  value = "service/${aws_ecs_cluster.default.name}/${aws_ecs_service.default.name}"
}

output "iam_role_arm" {
  description = "The IAM Role attached to Fargate services"
  value = aws_iam_role.container.arn
}

output "iam_role_name" {
  description = "The IAM Role attached to Fargate services"
  value = aws_iam_role.container.name
}

output "lb_arn" {
  description = "The Load Balancer arn"
  value = aws_alb.default.arn
}

output "lb_name" {
  description = "The Load Balancer name"
  value = aws_alb.default.name
}

output "lb_fqdns" {
  description = "The Load Balancer FQDNS"
  value = aws_alb.default.dns_name
}

output "route53_record" {
  value = aws_route53_record.submain.fqdn
}

output "log_group_arn" {
  value = aws_cloudwatch_log_group.default.arn
}