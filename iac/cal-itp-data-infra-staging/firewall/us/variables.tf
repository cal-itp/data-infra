data "terraform_remote_state" "networks" {
  backend = "local"

  config = {
    path = "../../networks/us/terraform.tfstate"
  }
}
