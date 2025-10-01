include {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules/aws/route53"
}

inputs = {
  project_name       = "activatree"
  domain_name        = "dev.activatree.com"
  environment = "prod"
}
