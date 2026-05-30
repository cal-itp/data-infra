provider "google" {
  project               = "cal-itp-data-infra"
  billing_project       = "cal-itp-data-infra"
  user_project_override = true
}

terraform {
  required_providers {
    google = {
      version = "~> 6.41.0"
    }
  }

  backend "gcs" {
    bucket = "calitp-prod-gcp-components-tfstate"
    prefix = "cal-itp-data-infra/gcs"
  }
}
