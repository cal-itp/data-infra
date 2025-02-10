data "terraform_remote_state" "networks" {
  backend = "local"

  config = {
    path = "../../networks/us-west1/terraform.tfstate"
  }
}
