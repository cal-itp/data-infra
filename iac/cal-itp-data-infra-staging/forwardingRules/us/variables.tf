data "terraform_remote_state" "networks" {
  backend = "local"

  config = {
    path = "../../networks/us/terraform.tfstate"
  }
}

data "terraform_remote_state" "regionBackendServices" {
  backend = "local"

  config = {
    path = "../../regionBackendServices/us/terraform.tfstate"
  }
}
