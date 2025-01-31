data "terraform_remote_state" "networks" {
  backend = "local"

  config = {
    path = "../../../../../generated/google/cal-itp-data-infra/networks/us-west1/terraform.tfstate"
  }
}

data "terraform_remote_state" "subnetworks" {
  backend = "local"

  config = {
    path = "../../../../../generated/google/cal-itp-data-infra/subnetworks/us-west1/terraform.tfstate"
  }
}
