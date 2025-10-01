# ===========
# ECS Cluster
# ===========

# ECS Cluster with container insights enabled for better observability
resource "aws_ecs_cluster" "this" {
  name = "${var.name}-${var.environment}"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "${var.name}-${var.environment}"
  }
}

# ==============================
# ECS Capacity Providers for EC2
# ==============================

# Creates capacity providers for each ASG passed in
resource "aws_ecs_capacity_provider" "this" {
  for_each = aws_autoscaling_group.this

  name = "${each.key}-cp-${var.environment}"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = each.value.arn
    managed_termination_protection = "ENABLED"
    managed_draining               = "ENABLED"

    managed_scaling {
      maximum_scaling_step_size = 2
      minimum_scaling_step_size = 1
      status                    = "ENABLED"
      target_capacity           = 80
    }
  }

  tags = {
    Name = "${each.key}-cp-${var.environment}"
  }
}

# ========================================
# Attach Capacity Providers to ECS Cluster
# ========================================

# Mixed capacity: EC2 + FARGATE
resource "aws_ecs_cluster_capacity_providers" "this" {
  cluster_name = aws_ecs_cluster.this.name

  capacity_providers = concat(
    [for cp in aws_ecs_capacity_provider.this : cp.name], # all created ASG CPs (0 if none)
    ["FARGATE"]                                           # always include FARGATE
  )

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 1
    base              = 1
  }
}
