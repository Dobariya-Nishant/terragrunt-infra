output "hostedzone_id" {
  value = aws_route53_zone.this.id
}

output "hostedzone_arn" {
  value = aws_route53_zone.this.arn
}

output "hostedzone_name_servers" {
  value = aws_route53_zone.this.name_servers
}