# Route 53
locals {
  alias_name = var.enable_nlb ? aws_lb.network_load_balancer[0].dns_name : aws_alb.default[0].dns_name
  alias_zone_id = var.enable_nlb ? aws_lb.network_load_balancer[0].zone_id : aws_alb.default[0].zone_id
}

resource "aws_route53_record" "submain" {
  zone_id = var.route53_zone_id
  name    = "${local.route53_record}.${var.route53_root_domain}"
  type    = "A"

  alias {
    name                   = local.alias_name
    zone_id                = local.alias_zone_id
    evaluate_target_health = true
  }
}
