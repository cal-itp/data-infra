data "terraform_remote_state" "urlMaps" {
  backend = "local"

  config = {
    path = "../../urlMaps/us/terraform.tfstate"
  }
}
