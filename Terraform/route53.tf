# Route53 Hosted Zone
data "aws_route53_zone" "main" {
  name = "daveops.pro"
}

# Add DNS A record for sedaro-nano.daveops.pro
resource "aws_route53_record" "sedaro-nano" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "sedaro-nano.daveops.pro"
  type    = "A"

  alias {
    name                   = aws_lb.alb.dns_name
    zone_id                = aws_lb.alb.zone_id
    evaluate_target_health = true
  }
}

