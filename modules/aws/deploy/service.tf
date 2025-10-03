# ============
# ECS Services
# ============

# ECS Services based on above task definitions
resource "aws_ecs_service" "this" {
  for_each        = var.services

  name            = "${each.key}-sv-${var.environment}"
  cluster         = var.ecs_cluster_id
  task_definition = aws_ecs_task_definition.this[each.key].arn
  desired_count   = each.value.desired_count

  network_configuration {
    subnets          = each.value.subnet_ids
    security_groups  = [aws_security_group.this[each.key].id]
    assign_public_ip = false
  }

  # Capacity provider strategy if provided, else FARGATE
  dynamic "capacity_provider_strategy" {
    for_each = each.value.capacity_provider_name != null ? [each.value.capacity_provider_name] : ["FARGATE"]
    content {
      capacity_provider = capacity_provider_strategy.value
      weight            = 1
      base              = 1
    }
  }

  deployment_controller {
    type = "CODE_DEPLOY"
  }

  # Attach load balancer if defined
  dynamic "load_balancer" {
    for_each = each.value.load_balancer_config != null ? [each.value.load_balancer_config] : []
    content {
      container_name   = each.value.task.name
      target_group_arn = load_balancer.value.blue_target_group_arn
      container_port   = load_balancer.value.container_port
    }
  }

  # Placement only for EC2
  dynamic "ordered_placement_strategy" {
    for_each = each.value.capacity_provider_name != null ? [1] : []
    content {
      type  = "spread"
      field = "instanceId"
    }
  }

  tags = {
    Name = "${each.value.name}-sv-${var.environment}"
  }
}

resource "aws_cloudwatch_log_group" "this" {
  for_each     = var.services

  name              = "/ecs/${each.value.task.name}"
  retention_in_days = 7
}

# ====================
# ECS Task Definitions
# ====================  

# ECS Task Definitions for all tasks provided via `var.tasks`
resource "aws_ecs_task_definition" "this" {
  for_each     = var.services

  family       = "${each.value.task.name}-td-${var.environment}"
  cpu          = each.value.task.cpu
  memory       = each.value.task.memory
  network_mode = "awsvpc"

  requires_compatibilities = each.value.capacity_provider_name == null ? ["FARGATE"] : []

  execution_role_arn = aws_iam_role.ecs_task_execution_role[each.key].arn
  task_role_arn      = try(each.value.task.task_role_arn, null)
# sudo mount -t nfs4 -o nfsvers=4.1 fs-0a43e7af5aa7431b9.efs.us-east-1.amazonaws.com:/ /mnt
  container_definitions = jsonencode([
    {
      name         = each.value.task.name
      image        = each.value.task.image_uri
      essential    = each.value.task.essential
      environment  = try(each.value.task.environment, [])
      portMappings = try(each.value.task.portMappings, [])
      mountPoints  = try(each.value.task.mountPoints, [])
      command      = each.value.task.command
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.this[each.key].name
          awslogs-region        = "us-east-1"
          awslogs-stream-prefix = var.name
        }
      }
    }
  ])

  

  dynamic "volume" {
    for_each = each.value.volumes
    content {
      name = "jenkins-data"
      efs_volume_configuration {
        file_system_id =     volume.value.efs_id
        root_directory      = volume.value.root_directory
        transit_encryption =  "ENABLED"
      }
    }
  }
  
  tags = {
    Name = "${each.value.task.name}-td-${var.environment}"
  }
}

# ==========================
# Auto Scaling (ECS Service)
# ==========================

# Register ECS Service as scalable
resource "aws_appautoscaling_target" "ecs_service" {
  for_each = aws_ecs_service.this

  max_capacity       = 10
  min_capacity       = 1
  resource_id        = "service/${var.ecs_cluster_name}/${each.value.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# CPU-based auto-scaling policy
resource "aws_appautoscaling_policy" "cpu_scaling" {
  for_each = aws_ecs_service.this

  name               = "${each.value.name}-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_service[each.key].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_service[each.key].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_service[each.key].service_namespace

  target_tracking_scaling_policy_configuration {
    target_value = 70.0
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
  }
}

# Memory-based auto-scaling policy
resource "aws_appautoscaling_policy" "memory_scaling" {
  for_each = aws_ecs_service.this

  name               = "${each.value.name}-memory-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_service[each.key].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_service[each.key].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_service[each.key].service_namespace

  target_tracking_scaling_policy_configuration {
    target_value = 70.0
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
  }
}

# ============================
# Security Group (ECS Service)
# ============================

resource "aws_security_group" "this" {
  for_each = var.services

  name        = "${each.value.name}-sv-sg-${var.environment}"
  description = "tasks Security group"
  vpc_id      = each.value.vpc_id

  dynamic "ingress" {
    for_each = each.value.load_balancer_config != null ? [each.value.load_balancer_config] : []
    content {
      description     = "Allow LoadBalancer traffic"
      from_port       = ingress.value.container_port
      to_port         = ingress.value.container_port
      protocol        = "tcp"
      security_groups = [ingress.value.sg_id]
    }
  }

  dynamic "ingress" {
    for_each = each.value.sg_rules
    content {
      description     = ingress.value.description
      from_port       = ingress.value.from_port
      to_port         = ingress.value.to_port
      protocol        = ingress.value.protocol
      cidr_blocks     = ingress.value.cidr_blocks
    }
  }

  dynamic "ingress" {
    for_each = each.value.enable_public_http == true ? [1] : []
    content {
      description       = "Allow HTTP"
      from_port         = 80
      to_port           = 80
      protocol          = "tcp"
      cidr_blocks       = ["0.0.0.0/0"]
    }
  }

  dynamic "ingress" {
    for_each = each.value.enable_public_https == true ? [1] : []
    content {
      description       = "Allow HTTPS"
      from_port         = 443
      to_port           = 443
      protocol          = "tcp"
      cidr_blocks       = ["0.0.0.0/0"]
    }
  }

  egress {
    description       = "Allow all outbound traffic"
    from_port         = 0
    to_port           = 0
    protocol          = "-1"
    cidr_blocks       = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${each.value.name}-sv-sg-${var.environment}"
  }
}

# ====================
# IAM Roles & Policies
# ====================

# IAM role trust policy for ECS task execution role
data "aws_iam_policy_document" "ecs_task_execution_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

# AWS managed policy for ECS task execution role
data "aws_iam_policy" "ecs_task_execution_role_policy" {
  name = "AmazonECSTaskExecutionRolePolicy"
}

# ECS Task Execution IAM Role
resource "aws_iam_role" "ecs_task_execution_role" {
  for_each = var.services

  name        = "${each.value.name}-task-execution-role-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_execution_role.json

  tags = {
    Name = "${each.value.name}-task-execution-role-${var.environment}"
  }
}

# Attach managed execution policy to role
resource "aws_iam_role_policy_attachment" "task_execution_policy_attach" {
  for_each = var.services

  role       = aws_iam_role.ecs_task_execution_role[each.key].name
  policy_arn = data.aws_iam_policy.ecs_task_execution_role_policy.arn
}
