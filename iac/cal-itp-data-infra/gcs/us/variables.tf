locals {
  environment_buckets = toset([
    "calitp-gtfs-schedule-manual",
    "calitp-kuba",
    "calitp-gtfs-rt-archiver",
  ])

  requester_pays_buckets = toset([
    "calitp-tides",
  ])

  site_buckets = toset([
    "calitp-tides-site",
    "calitp-analysis",
    "calitp-reports",
    "calitp-dbt-docs",
    "calitp-gtfs"
  ])
}

data "terraform_remote_state" "iam" {
  backend = "gcs"

  config = {
    bucket = "calitp-prod-gcp-components-tfstate"
    prefix = "cal-itp-data-infra/iam"
  }
}
