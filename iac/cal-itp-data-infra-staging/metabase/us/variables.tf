data "terraform_remote_state" "iam" {
  backend = "gcs"

  config = {
    bucket = "calitp-staging-gcp-components-tfstate"
    prefix = "cal-itp-data-infra-staging/iam"
  }
}

resource "random_password" "metabase-staging-secret-key" {
  special = false
  length  = 50
}

resource "random_password" "metabase-staging-database" {
  special = false
  length  = 32
}

locals {
  domain = "metabase-staging.dds.dot.ca.gov"
}
