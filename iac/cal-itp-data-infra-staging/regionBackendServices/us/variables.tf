data "terraform_remote_state" "healthChecks" {
  backend = "local"

  config = {
    path = "../../healthChecks/us/terraform.tfstate"
  }
}

data "terraform_remote_state" "instanceGroupManagers" {
  backend = "local"

  config = {
    path = "../../instanceGroupManagers/us/terraform.tfstate"
  }
}

data "terraform_remote_state" "regionInstanceGroupManagers" {
  backend = "local"

  config = {
    path = "../../regionInstanceGroupManagers/us/terraform.tfstate"
  }
}
