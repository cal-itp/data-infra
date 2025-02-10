data "terraform_remote_state" "networks" {
  backend = "local"

  config = {
    path = "../../networks/us-west1/terraform.tfstate"
  }
}

data "terraform_remote_state" "subnetworks" {
  backend = "local"

  config = {
    path = "../../subnetworks/us-west1/terraform.tfstate"
  }
}
