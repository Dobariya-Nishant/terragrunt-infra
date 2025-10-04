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

resource "aws_lb_target_group" "blue" {
  for_each = var.target_groups

  name                          = "blue-${each.value.name}-tg-${var.environment}"
  port                          = each.value.port
  protocol                      = each.value.protocol
  vpc_id                        = var.vpc_id
  target_type                   = each.value.target_type
  load_balancing_algorithm_type = "round_robin"

  health_check {
    enabled             = true
    interval            = 30
    path                = each.value.health_check_path
    port                = "traffic-port"
    healthy_threshold   = 3
    unhealthy_threshold = 2
    timeout             = 5
    matcher             = "200"
  }

  tags = {
    Name = "blue-${each.value.name}-tg-${var.environment}"
  }
}

resource "aws_lb_target_group" "green" {
  for_each = var.target_groups

  name                          = "green-${each.value.name}-tg-${var.environment}"
  port                          = each.value.port
  protocol                      = each.value.protocol
  vpc_id                        = var.vpc_id
  target_type                   = each.value.target_type
  load_balancing_algorithm_type = "round_robin"

  health_check {
    enabled             = true
    interval            = 30
    path                = each.value.health_check_path
    port                = "traffic-port"
    healthy_threshold   = 6
    unhealthy_threshold = 2
    timeout             = 5
    matcher             = "200"
  }

  tags = {
    Name = "green-${each.value.name}-tg-${var.environment}"
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

  certificate_arn = var.acm_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blue[var.listener.target_group_key].arn
  }

  tags = {
    Name = "${var.listener.name}-https-${var.environment}"
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
    Name = "${var.listener.name}-http-${var.environment}"
  }
}

# ==========================================
# 📜 ALB Listener Rules (Path-based Routing)
# ==========================================

resource "aws_lb_listener_rule" "this" {
  for_each = var.listener.rules

  listener_arn = aws_lb_listener.https.arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blue[each.value.target_group_key].arn
  }

  condition {
    dynamic "path_pattern" {
      for_each = try(each.value.patterns, null) != null ? [1] : []
      content {
        values = each.value.patterns
      }
    }

    dynamic "host_header" {
      for_each = try(each.value.hosts, null) != null ? [1] : []
      content {
        values = each.value.hosts
      }
    }
  }


  tags = {
    Description = each.value.description
  }
}

# =========================
# 🔐 Security Group for ALB
# =========================

resource "aws_security_group" "this" {
  name   = local.name
  vpc_id = var.vpc_id

  ingress {
    description = "Allow HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = local.name
  }
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