provider "google" {
  project = "cal-itp-data-infra"
}

terraform {
	required_providers {
		google = {
	    version = "~> 6.19.0"
		}
  }
}
