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
    id                 = "mock-alb-id"
    sg_id              = "mock-alb-sg-id"
    https_listener_arn = "mock-alb-listener-arn"
    blue_tg = {
      jenkins = {
        name = "mock-tg-name"
        arn  = "mock-tg-arn"
      }
    }
    green_tg = {
      jenkins = {
        name = "mock-tg-name"
        arn  = "mock-tg-arn"
      }
    }
  }
}

dependency "jenkins_efs" {
  config_path = "../efs/jenkins"

  # Optional: helpful for plan if VPC is not applied yet
  mock_outputs = {
    id   = "mock-efs-id"
    name = "mock-efs-name"
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

    jenkins = {
      name                   = "jenkins"
      desired_count          = 1
      vpc_id                 = dependency.vpc.outputs.vpc_id
      subnet_ids             = dependency.vpc.outputs.private_subent_ids
      # capacity_provider_name = dependency.ecs.outputs.asg_cp["jenkins"].name

      load_balancer_config = {
        sg_id                   = dependency.alb.outputs.sg_id
        listener_arn            = dependency.alb.outputs.https_listener_arn
        blue_target_group_name  = dependency.alb.outputs.blue_tg["jenkins"].name
        green_target_group_name = dependency.alb.outputs.green_tg["jenkins"].name
        blue_target_group_arn   = dependency.alb.outputs.blue_tg["jenkins"].arn
        green_target_group_arn  = dependency.alb.outputs.green_tg["jenkins"].arn
        container_port          = 8080
      }

      volumes = [
        {
          name          = "jenkins-data"
          efs_id  = dependency.jenkins_efs.outputs.id
          root_directory = "/"
        }
      ]

      sg_rules = [
        {
          description     = "allow port for jenkins agents access"
          from_port       = 50000
          to_port         = 50000
          protocol        = "tcp"
          cidr_blocks     = ["10.0.0.0/16"]
        }
      ]

      task = {
        name      = "jenkins"
        cpu       = 256
        memory    = 512
        image_uri = "jenkins/jenkins:lts-alpine"
        essential = true
        portMappings = [
          {
            containerPort = 8080
            hostPort      = 8080
            protocol      = "tcp"
          }
        ]
        mountPoints = [
          {
            sourceVolume  = "jenkins-data"
            containerPath = "/var/jenkins_home"
            readOnly      = false
          }
        ]
      }
    }
  }
}