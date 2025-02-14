data "terraform_remote_state" "backendServices" {
  backend = "local"

  config = {
    path = "../../backendServices/us/terraform.tfstate"
  }
}
