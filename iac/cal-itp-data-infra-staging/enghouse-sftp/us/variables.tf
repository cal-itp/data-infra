locals {
  sftp_user = "enghouse"
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

data "google_secret_manager_secret_version" "enghouse-sftp-public-key" {
  secret = "enghouse-sftp-public-key"
}

data "google_secret_manager_secret_version" "enghouse-sftp-private-key" {
  secret = "enghouse-sftp-private-key"
}

data "google_secret_manager_secret_version" "enghouse-sftp-authorizedkey" {
  secret = "enghouse-sftp-authorizedkey"
}
