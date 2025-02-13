data "terraform_remote_state" "instanceTemplates" {
  backend = "local"

  config = {
    path = "../../instanceTemplates/us/terraform.tfstate"
  }
}
