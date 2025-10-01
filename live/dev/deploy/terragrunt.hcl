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

dependency "ecs" {
  config_path = "../ecs"

  # Optional: helpful for plan if VPC is not applied yet
  mock_outputs = {
    id    = "mock-cluster-id"
    name  = "mock-cluster-name"
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
  name = local.env_vars.locals.project_name
  project_name = local.env_vars.locals.project_name
  environment  = local.env_vars.locals.environment

  ecs_cluster_id = local.ecs.locals.id
  ecs_cluster_name = local.ecs.locals.name

  vpc_id =  dependency.vpc.outputs.vpc_id

  
}
