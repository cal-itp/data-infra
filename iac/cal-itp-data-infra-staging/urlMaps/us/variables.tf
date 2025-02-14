data "terraform_remote_state" "backendServices" {
  backend = "local"

  config = {
    path = "../../backendServices/us/terraform.tfstate"
  }
}

data "terraform_remote_state" "regionBackendServices" {
  backend = "local"

  config = {
    path = "../../regionBackendServices/us/terraform.tfstate"
  }
}
