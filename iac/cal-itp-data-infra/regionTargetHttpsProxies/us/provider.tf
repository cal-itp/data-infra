provider "google" {
  project = "cal-itp-data-infra"
}

terraform {
  required_providers {
    google = {
      version = "~> 4.59.0"
    }
  }
}
