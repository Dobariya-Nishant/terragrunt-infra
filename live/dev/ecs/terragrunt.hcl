include {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules/aws/ecs"
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

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

inputs = {
  name         = local.env_vars.locals.project_name
  project_name = local.env_vars.locals.project_name
  environment  = local.env_vars.locals.environment
  vpc_id       = dependency.vpc.outputs.vpc_id

  # asg = {
  #   jenkins = {
  #     instance_type = "t3.micro"
  #     min_size      = 1
  #     max_size      = 2
  #     subnet_ids    = dependency.vpc.outputs.private_subent_ids
  #   }
  # }
}
