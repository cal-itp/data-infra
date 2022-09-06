provider "google" {
  project = "cal-itp-data-infra"
  region  = var.compute_region
}

terraform {
  backend "gcs" {
  }
}

data "google_client_openid_userinfo" "me" {
}

locals {
  pfx = var.env_name == "local" ? replace(split("@", data.google_client_openid_userinfo.me.email)[0], ".", "") : var.env_name

  std_labels = {
    "Creator" = data.google_client_openid_userinfo.me.email
    "Environment" = var.env_name
  }
}
