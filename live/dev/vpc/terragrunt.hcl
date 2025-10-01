include {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules/aws/vpc"
}

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

inputs = {
  name               = "${local.env_vars.locals.project_name}-vpc"
  project_name       = local.env_vars.locals.project_name
  environment        = local.env_vars.locals.environment
  enable_nat_gateway = true
  cidr_block         = "10.0.0.0/16"
  public_subnets     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets    = ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
}
