data "terraform_remote_state" "targetHttpProxies" {
  backend = "local"

  config = {
    path = "../../targetHttpProxies/us/terraform.tfstate"
  }
}

data "terraform_remote_state" "targetHttpsProxies" {
  backend = "local"

  config = {
    path = "../../targetHttpsProxies/us/terraform.tfstate"
  }
}

data "terraform_remote_state" "targetSslProxies" {
  backend = "local"

  config = {
    path = "../../targetSslProxies/us/terraform.tfstate"
  }
}
