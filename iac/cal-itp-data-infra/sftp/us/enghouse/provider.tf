provider "google" {
  project = "cal-itp-data-infra"
}

terraform {
  required_providers {
    google = {
      version = "~> 6.41.0"
    }
  }

  backend "gcs" {
    bucket = "calitp-prod-gcp-components-tfstate"
    prefix = "cal-itp-data-infra/sftp-enghouse"
  }

}

data "google_client_config" "default" {}
provider "kubernetes" {
  host                   = "https://${data.terraform_remote_state.gke.outputs.google_container_cluster_sftp-endpoints_endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(data.terraform_remote_state.gke.outputs.google_container_cluster_sftp-endpoints_ca_certificate)
}
