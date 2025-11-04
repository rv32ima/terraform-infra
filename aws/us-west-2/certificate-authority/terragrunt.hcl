include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "."
}

inputs = {
  availability_zones = ["us-west-2a", "us-west-2b"]
  prefix = "ca"
}