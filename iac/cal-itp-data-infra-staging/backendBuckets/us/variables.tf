data "terraform_remote_state" "gcs" {
  backend = "local"

  config = {
    path = "../../gcs/us/terraform.tfstate"
  }
}
