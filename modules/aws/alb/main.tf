# ===================================
# 🏗️  Application Load Balancer (ALB)
# ===================================

resource "aws_lb" "this" {
  name               = local.name
  internal           = false                        
  load_balancer_type = "application"                
  security_groups    = [aws_security_group.this.id] 
  subnets            = var.subnet_ids               

  enable_cross_zone_load_balancing = true

  tags = {
    Name = local.name
  }
}

# ====================================
# 🎯 Target Groups (for ALB Listeners)
# ====================================

resource "aws_lb_target_group" "blue_client" {
  name                          = "blue-client-${local.name}" 
  port                          = 80
  protocol                      = "HTTP" 
  vpc_id                        = var.vpc_id
  target_type                   = "ip" 
  load_balancing_algorithm_type = "round_robin"

  health_check {
    enabled             = true
    interval            = 30  
    path                = "/"
    port                = "traffic-port"
    healthy_threshold   = 3     
    unhealthy_threshold = 2     
    timeout             = 5     
    matcher             = "200" 
  }

  tags = {
    Name = "blue-client-${local.name}"
  }
}

resource "aws_lb_target_group" "green_client" {
  name                          = "green-client-${local.name}"
  port                          = 80
  protocol                      = "HTTP" 
  vpc_id                        = var.vpc_id
  target_type                   = "ip" 
  load_balancing_algorithm_type = "round_robin"

  health_check {
    enabled             = true
    interval            = 30  
    path                = "/" 
    port                = "traffic-port"
    healthy_threshold   = 3     
    unhealthy_threshold = 2     
    timeout             = 5     
    matcher             = "200" 
  }

  tags = {
    Name = "green-client-${local.name}"
  }
}

resource "aws_lb_target_group" "blue_api" {
  name                          = "blue-api-${local.name}"
  port                          = 80
  protocol                      = "HTTP" 
  vpc_id                        = var.vpc_id
  target_type                   = "ip"
  load_balancing_algorithm_type = "round_robin"

  health_check {
    enabled             = true
    interval            = 30  
    path                = "/" 
    port                = "traffic-port"
    healthy_threshold   = 3     
    unhealthy_threshold = 2     
    timeout             = 5     
    matcher             = "200" 
  }

  tags = {
    Name = "blue-api-${local.name}"
  }
}

resource "aws_lb_target_group" "green_api" {
  name                          = "green-api-${local.name}"
  port                          = 80
  protocol                      = "HTTP" 
  vpc_id                        = var.vpc_id
  target_type                   = "ip" 
  load_balancing_algorithm_type = "round_robin"

  health_check {
    enabled             = true
    interval            = 30  
    path                = "/"
    port                = "traffic-port"
    healthy_threshold   = 3     
    unhealthy_threshold = 2     
    timeout             = 5     
    matcher             = "200"
  }

  tags = {
    Name = "green-api-${local.name}"
  }
}

# ================================
# 🎧 ALB Listeners (Port 80 / 443)
# ================================

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.this.arn
  port              = 443     
  protocol          = "HTTPS" 
  ssl_policy        = "ELBSecurityPolicy-2016-08"

  certificate_arn = aws_acm_certificate.this.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blue_client.arn
  }

  depends_on = [
    aws_acm_certificate_validation.this
  ]

  tags = {
    Name = "https-${local.name}"
  }
}

# HTTP listener -> Redirect to HTTPS
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  tags = {
    Name = "http-${local.name}"
  }
}

# ==========================================
# 📜 ALB Listener Rules (Path-based Routing)
# ==========================================

resource "aws_lb_listener_rule" "api_https" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 1

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blue_api.arn
  }

  condition {
    path_pattern {
      values = ["/api"]
    }
  }

  tags = {
    Name = "api-https-${local.name}"
  }
}

# =========================
# 🔐 Security Group for ALB
# =========================

resource "aws_security_group" "this" {
  name   = local.name
  vpc_id = var.vpc_id

  ingress {
    description       = "Allow HTTPS"
    from_port         = 443
    to_port           = 443
    protocol          = "tcp"
    cidr_blocks       = ["0.0.0.0/0"]
  }

  ingress {
    description       = "Allow HTTP"
    from_port         = 80
    to_port           = 80
    protocol          = "tcp"
    cidr_blocks       = ["0.0.0.0/0"]
  }

  egress {
    description       = "Allow all outbound traffic"
    from_port         = 0
    to_port           = 0
    protocol          = "-1"
    cidr_blocks       = ["0.0.0.0/0"]
  }

  tags = {
    Name = local.name
  }
}

# ===================================
# 2. ACM Certificate (DNS validation)
# ===================================
resource "aws_acm_certificate" "this" {
  domain_name       = local.domain_name
  validation_method = "DNS"

  subject_alternative_names = [
    "www.${local.domain_name}"
  ]

  tags = {
    Name = "${local.name}-cf"
  }
}

# =================================
# 3. DNS records for ACM validation
# =================================
resource "aws_route53_record" "cert_records" {
  for_each = {
    for dvo in aws_acm_certificate.this.domain_validation_options : dvo.domain_name => dvo
  }

  zone_id = var.hostedzone_id
  name    = each.value.resource_record_name
  type    = each.value.resource_record_type
  records = [each.value.resource_record_value]
  ttl     = 60
}

# =============================
# 4. ACM Certificate Validation
# =============================
resource "aws_acm_certificate_validation" "this" {
  certificate_arn         = aws_acm_certificate.this.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_records : record.fqdn]
}

# ========================================
# 7. Route53 record to point domain to ALB
# ========================================
resource "aws_route53_record" "alb_alias" {
  zone_id = var.hostedzone_id
  name    = local.domain_name
  type    = "A"

  alias {
    name                   = aws_lb.this.dns_name
    zone_id                = aws_lb.this.zone_id
    evaluate_target_health = true
  }
}