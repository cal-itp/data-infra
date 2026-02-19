data "terraform_remote_state" "iam" {
  backend = "gcs"

  config = {
    bucket = "calitp-prod-gcp-components-tfstate"
    prefix = "cal-itp-data-infra/iam"
  }
}

resource "random_password" "metabase-secret-key" {
  special = false
  length  = 50
}

resource "random_password" "metabase-database" {
  special = false
  length  = 32
}

locals {
  domain = "metabase.dds.dot.ca.gov"
}
