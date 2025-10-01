# ==============
# 1. Hosted Zone
# ==============
resource "aws_route53_zone" "this" {
  name = var.domain_name
}

# Optional: www -> root redirect
resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.this.zone_id
  name    = "www.${var.domain_name}"
  type    = "CNAME"
  ttl     = 300
  records = [var.domain_name]
}