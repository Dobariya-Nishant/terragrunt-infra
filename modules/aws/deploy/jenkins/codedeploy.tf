# ==============
# CodeDeploy App
# ==============
resource "aws_codedeploy_app" "this" {
  name             = "${var.name}-cd-${var.environment}"
  compute_platform = "ECS"
}

# ===========================
# CodeDeploy Deployment Group
# ===========================
resource "aws_codedeploy_deployment_group" "ecs_deploy_group" {
  app_name              = aws_codedeploy_app.this.name
  deployment_group_name = "${var.name}-dg-${var.environment}"
  service_role_arn      = aws_iam_role.this.arn

  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"

  ecs_service {
    cluster_name = var.ecs_cluster_name
    service_name = aws_ecs_service.this.name
  }

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }

    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 5
    }
  }

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [var.load_balancer_config.listener_arn]
      }

      target_group {
        name = var.load_balancer_config.blue_target_group_name
      }

      target_group {
        name = var.load_balancer_config.green_target_group_name
      }
    }
  }

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }
}

# =======================
# IAM Role for CodeDeploy
# =======================
resource "aws_iam_role" "this" {
  name = "${var.name}-codedeploy-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "codedeploy.amazonaws.com"
      }
    }]
  })
}

data "aws_iam_policy" "ecs_code_deploy_role_policy" {
  name = "AWSCodeDeployRoleForECS"
}

resource "aws_iam_role_policy_attachment" "this" {
  role       = aws_iam_role.this.name
  policy_arn = data.aws_iam_policy.ecs_code_deploy_role_policy.arn
}
