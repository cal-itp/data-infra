locals {
  environment_buckets = toset([
    "calitp-gtfs-schedule-manual",
    "calitp-kuba",
    "calitp-gtfs-rt-archiver"
  ])
}

data "terraform_remote_state" "iam" {
  backend = "gcs"

  config = {
    bucket = "calitp-prod-gcp-components-tfstate"
    prefix = "cal-itp-data-infra/iam"
  }
}
