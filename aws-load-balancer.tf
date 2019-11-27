# Load Balancer
locals {
  alb_listener_arn = local.using_auth0 ? aws_alb_listener.https_auth[0].arn : aws_alb_listener.https[0].arn
}

# application load balancer setting
resource "aws_alb" "default" {
  count = var.enable_nlb ? 0 : 1
  name = local.cannonical_name

  security_groups    = [aws_security_group.dmz.id]
  load_balancer_type = "application"
  internal           = false

  subnets = var.lb_subnet_ids

  tags = local.app_tags
}

resource "aws_alb_listener" "http" {
  count = var.enable_nlb ? 0 : 1
  load_balancer_arn = aws_alb.default[0].arn

  port     = 80
  protocol = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = 443
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_alb_listener" "https" {
  count = var.enable_nlb ? 0 : local.using_auth0 ? 0 : 1
  # count = local.using_auth0 ? 0 : 1
  load_balancer_arn = aws_alb.default[0].arn

  port       = 443
  protocol   = "HTTPS"
  ssl_policy = "ELBSecurityPolicy-2016-08"

  certificate_arn = var.acm_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.blue[0].arn
  }

  lifecycle {
    ignore_changes = [ default_action ]
  }
}

resource "aws_alb_listener" "https_auth" {
  count = var.enable_nlb ? 0 : local.using_auth0 ? 1 : 0
  # count = local.using_auth0 ? 1 : 0
  load_balancer_arn = aws_alb.default[0].arn

  port       = 443
  protocol   = "HTTPS"
  ssl_policy = "ELBSecurityPolicy-2016-08"

  certificate_arn = var.acm_certificate_arn

  default_action {
    type = "authenticate-oidc"

    authenticate_oidc {
      authorization_endpoint = var.auth0_authorization_endpoint
      client_id              = var.auth0_client_id
      client_secret          = var.auth0_client_secret
      issuer                 = var.auth0_issuer
      token_endpoint         = var.auth0_token_endpoint
      user_info_endpoint     = var.auth0_user_info_endpoint
    }
  }

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.blue[0].arn
  }

  lifecycle {
    ignore_changes = [ default_action ]
  }
}

resource "aws_alb_target_group" "blue" {
  count = var.enable_nlb ? 0 : 1
  name        = "${local.cannonical_name}-blue"
  port        = var.ecs_port
  protocol    = var.ecs_protocol
  vpc_id      = var.vpc_id
  target_type = "ip"

  deregistration_delay = var.lb_deregistration_delay
  slow_start = var.lb_slow_start

  health_check {
    path              = var.lb_health_check_path
    interval          = var.lb_health_check_interval
    timeout           = var.lb_health_check_timeout
    healthy_threshold = var.lb_health_check_threshold
    unhealthy_threshold = var.lb_health_failure_check_threshold
  }
}

resource "aws_alb_target_group" "green" {
  count = var.enable_nlb ? 0 : 1
  name        = "${local.cannonical_name}-green"
  port        = var.ecs_port
  protocol    = var.ecs_protocol
  vpc_id      = var.vpc_id
  target_type = "ip"

  deregistration_delay = var.lb_deregistration_delay
  slow_start = var.lb_slow_start

  health_check {
    path              = var.lb_health_check_path
    interval          = var.lb_health_check_interval
    timeout           = var.lb_health_check_timeout
    healthy_threshold = var.lb_health_check_threshold
    unhealthy_threshold = var.lb_health_failure_check_threshold
  }
}

# network load balancer setting
resource "aws_lb" "network_load_balancer" {
  count = var.enable_nlb ? 1 : 0
  name = local.cannonical_name

  load_balancer_type = "network"
  internal           = false

  subnets = var.lb_subnet_ids

  tags = local.app_tags
}
resource "aws_lb_listener" "ftp" {
  count = var.enable_nlb ? 1 : 0
  load_balancer_arn = aws_lb.network_load_balancer[0].arn

  port       = 21
  protocol   = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blue[0].arn
  }

  lifecycle {
    ignore_changes = [ default_action ]
  }
}
resource "aws_lb_listener" "http" {
  count = var.enable_nlb ? 1 : 0
  load_balancer_arn = aws_lb.network_load_balancer[0].arn

  port     = 80
  protocol = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blue[0].arn
  }
}
resource "aws_lb_listener" "https" {
  count = var.enable_nlb ? 1 : 0
  load_balancer_arn = aws_lb.network_load_balancer[0].arn

  port       = 443
  protocol   = "TLS"
  certificate_arn = var.acm_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blue[0].arn
  }

  lifecycle {
    ignore_changes = [ default_action ]
  }
}

resource "aws_lb_target_group" "blue" {
  count = var.enable_nlb ? 1 : 0
  name        = "${local.cannonical_name}-blue"
  port        = var.ecs_port
  protocol    = "TCP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  deregistration_delay = var.lb_deregistration_delay
  slow_start = var.lb_slow_start

  stickiness {
    enabled = false
    type = "lb_cookie"
  }

  health_check {
    path              = var.lb_health_check_path
    interval          = 30
    # timeout           = 10
    healthy_threshold = 3
    unhealthy_threshold = 3
  }
}

resource "aws_lb_target_group" "green" {
  count = var.enable_nlb ? 1 : 0
  name        = "${local.cannonical_name}-green"
  port        = var.ecs_port
  protocol    = "TCP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  deregistration_delay = var.lb_deregistration_delay
  slow_start = var.lb_slow_start

  stickiness {
    enabled = false
    type = "lb_cookie"
  }

  health_check {
    path              = var.lb_health_check_path
    interval          = 30
    # timeout           = 10
    healthy_threshold = 3
    unhealthy_threshold = 3
  }
}
