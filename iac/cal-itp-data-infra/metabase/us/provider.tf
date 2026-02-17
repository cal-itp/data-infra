provider "google" {
  project = "cal-itp-data-infra"
}

terraform {
  required_providers {
    google = {
      version = "~> 7.10.0"
    }
  }

  backend "gcs" {
    bucket = "calitp-prod-gcp-components-tfstate"
    prefix = "cal-itp-data-infra/metabase"
  }
}
