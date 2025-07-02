provider "google" {
  project = "cal-itp-data-infra"
}

provider "kubernetes" {
  host                   = "https://${data.terraform_remote_state.gke.outputs.google_container_cluster_airflow-jobs_endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(data.terraform_remote_state.gke.outputs.google_container_cluster_airflow-jobs_ca_certificate)

  ignore_annotations = [
    "^autopilot\\.gke\\.io\\/.*",
    "^cloud\\.google\\.com\\/.*"
  ]
}

terraform {
  required_providers {
    google = {
      version = "~> 6.41.0"
    }

    kubernetes = {
      version = "~> 2.37.0"
    }
  }

  backend "gcs" {
    bucket = "calitp-prod-gcp-components-tfstate"
    prefix = "cal-itp-data-infra/composer"
  }
}
