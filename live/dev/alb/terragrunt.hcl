include {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules/aws/alb"
}

dependency "vpc" {
  config_path = "../vpc"

  # Optional: helpful for plan if VPC is not applied yet
  mock_outputs = {
    vpc_id            = "vpc-mock"
    public_subent_ids = ["subnet-mock1", "subnet-mock2"]
  }
}

dependency "route53" {
  config_path = "../../global/route53"

  # Optional: helpful for plan if hostedzone is not applied yet
  mock_outputs = {
    hostedzone_id  = "mock-hostedzone-id"
    hostedzone_arn = "mock-hostedzone-arn"
  }
}

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

inputs = {
  name = local.env_vars.locals.project_name

  project_name = local.env_vars.locals.project_name
  environment  = local.env_vars.locals.environment
  domain_name  = local.env_vars.locals.domain_name

  vpc_id     = dependency.vpc.outputs.vpc_id
  subnet_ids = dependency.vpc.outputs.public_subent_ids

  hostedzone_id = dependency.route53.outputs.hostedzone_id

  target_groups = {
    web = {
      name        = "web"
      port        = 80
      protocol    = "HTTP"
      target_type = "ip"
    }
    jenkins = {
      name        = "jenkins"
      port        = 8080
      protocol    = "HTTP"
      target_type = "ip"
    }
  }

  listener = {
    name             = local.env_vars.locals.project_name
    target_group_key = "web"
    rules = {
      jenkins_rule = {
        description      = "Jenkins path routing"
        target_group_key = "jenkins"
        patterns         = ["/jenkins*"]
      }
    }
  }

}