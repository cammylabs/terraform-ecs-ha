# Route 53

resource "aws_route53_record" "submain" {
  zone_id = var.route53_zone_id
  name    = "${local.route53_record}.${var.route53_root_domain}"
  type    = "A"

  alias {
    name                   = aws_alb.default.dns_name
    zone_id                = aws_alb.default.zone_id
    evaluate_target_health = true
  }
}
