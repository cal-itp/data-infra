data "terraform_remote_state" "networks" {
  backend = "local"

  config = {
    path = "../../networks/us/terraform.tfstate"
  }
}

data "terraform_remote_state" "subnetworks" {
  backend = "local"

  config = {
    path = "../../subnetworks/us/terraform.tfstate"
  }
}
