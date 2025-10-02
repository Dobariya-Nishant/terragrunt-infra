include {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules/aws/deploy"
}

dependency "vpc" {
  config_path = "../vpc"

  # Optional: helpful for plan if VPC is not applied yet
  mock_outputs = {
    vpc_id             = "vpc-mock"
    public_subent_ids  = ["subnet-mock1", "subnet-mock2"]
    private_subent_ids = ["subnet-mock1", "subnet-mock2"]
  }
}

dependency "alb" {
  config_path = "../alb"

  # Optional: helpful for plan if VPC is not applied yet
  mock_outputs = {
    id                   = "mock-alb-id"
    sg_id                = "mock-alb-sg-id"
    https_listener_arn   = "mock-alb-listener-arn"
    blue_client_tg_arn   = "mock-blue-client-tg-arn"
    blue_client_tg_name  = "mock-blue-client-tg-name"
    green_client_tg_arn  = "mock-green-client-tg-arn"
    green_client_tg_name = "mock-green-client-tg-name"
    blue_api_tg_arn      = "mock-blue-api-tg-arn"
    blue_api_tg_name     = "mock-blue-api-tg-name"
    green_api_tg_arn     = "mock-green-api-tg-arn"
    green_api_tg_name    = "mock-green-api-tg-name"
  }
}

dependency "ecs" {
  config_path = "../ecs"

  # Optional: helpful for plan if VPC is not applied yet
  mock_outputs = {
    id   = "mock-cluster-id"
    name = "mock-cluster-name"
    asg_cp = {
      k = {
        name = "mock-k-name"
        arn  = "mock-k-arn"
      }
    }
  }
}

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

inputs = {
  name         = local.env_vars.locals.project_name
  project_name = local.env_vars.locals.project_name
  environment  = local.env_vars.locals.environment

  ecs_cluster_id   = dependency.ecs.outputs.id
  ecs_cluster_name = dependency.ecs.outputs.name

  services = {

    client = {
      name                   = "client"
      desired_count          = 1
      vpc_id                 = dependency.vpc.outputs.vpc_id
      subnet_ids             = dependency.vpc.outputs.private_subent_ids
      capacity_provider_name = dependency.ecs.outputs.asg_cp["client"].name
      enable_public_http     = true
      enable_public_https    = false

      load_balancer_config = {
        sg_id                   = dependency.alb.outputs.sg_id
        listener_arn            = dependency.alb.outputs.https_listener_arn
        blue_target_group_name  = dependency.alb.outputs.blue_client_tg_name
        green_target_group_name = dependency.alb.outputs.green_client_tg_name
        blue_target_group_arn   = dependency.alb.outputs.blue_client_tg_arn
        green_target_group_arn  = dependency.alb.outputs.green_client_tg_arn
        container_port          = 80
      }

      task = {
        name      = "nginx-client"
        cpu       = 256
        memory    = 512
        image_uri = "nginx:latest"
        essential = true
        portMappings = [
          {
            containerPort = 80
            hostPort      = 80
            protocol      = "tcp"
          }
        ]
      }
    }
  }
}