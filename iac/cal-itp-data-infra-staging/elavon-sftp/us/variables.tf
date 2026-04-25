locals {
  sftp_user = "elavon"
}

data "terraform_remote_state" "gcs" {
  backend = "gcs"

  config = {
    bucket = "calitp-staging-gcp-components-tfstate"
    prefix = "cal-itp-data-infra-staging/gcs"
  }
}

data "terraform_remote_state" "gke" {
  backend = "gcs"

  config = {
    bucket = "calitp-staging-gcp-components-tfstate"
    prefix = "cal-itp-data-infra-staging/gke"
  }
}

data "terraform_remote_state" "iam" {
  backend = "gcs"

  config = {
    bucket = "calitp-staging-gcp-components-tfstate"
    prefix = "cal-itp-data-infra-staging/iam"
  }
}

data "terraform_remote_state" "networks" {
  backend = "gcs"

  config = {
    bucket = "calitp-staging-gcp-components-tfstate"
    prefix = "cal-itp-data-infra-staging/networks"
  }
}

data "google_secret_manager_secret_version" "elavon-sftp-public-key" {
  secret = "elavon-sftp-public-key"
}

data "google_secret_manager_secret_version" "elavon-sftp-private-key" {
  secret = "elavon-sftp-private-key"
}

data "google_secret_manager_secret_version" "elavon-sftp-authorizedkey" {
  secret = "elavon-sftp-authorizedkey"
}
