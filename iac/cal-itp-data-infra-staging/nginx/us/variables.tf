data "google_client_config" "default" {}

data "terraform_remote_state" "gke" {
  backend = "gcs"

  config = {
    bucket = "calitp-staging-gcp-components-tfstate"
    prefix = "cal-itp-data-infra-staging/gke"
  }
}
