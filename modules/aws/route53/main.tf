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

resource "aws_acm_certificate" "this" {
  domain_name       = "*.${var.domain_name}"  # wildcard for all subdomains
  validation_method = "DNS"

  # optional: include root domain as well
  subject_alternative_names = [
    var.domain_name  # allows example.com in addition to *.example.com
  ]

  tags = {
    Name = "${var.domain_name}-cf"
  }
}

resource "aws_route53_record" "cert_records" {
  for_each = {
    for dvo in aws_acm_certificate.this.domain_validation_options : dvo.domain_name => dvo
  }

  zone_id = aws_route53_zone.this.id
  name    = each.value.resource_record_name
  type    = each.value.resource_record_type
  records = [each.value.resource_record_value]
  allow_overwrite = true
  ttl     = 60
}

# =============================
# 4. ACM Certificate Validation
# =============================
resource "aws_acm_certificate_validation" "this" {
  certificate_arn         = aws_acm_certificate.this.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_records : record.fqdn]
}