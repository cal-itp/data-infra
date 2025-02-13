provider "google" {
  project = "cal-itp-data-infra-staging"
}

terraform {
  required_providers {
    google = {
      version = "~> 6.19.0"
      source  = "hashicorp/google"
    }
  }
}
