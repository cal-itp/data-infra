locals {
  environment_buckets = toset([
    "calitp-staging-aggregator-scraper",
    "calitp-staging-airtable",
    "calitp-staging-amplitude-benefits-events",
    "calitp-staging-analysis-output-models",
    "calitp-staging-elavon-parsed",
    "calitp-staging-elavon-raw",
    "calitp-staging-gtfs-download-config",
    "calitp-staging-gtfs-download-config-test",
    "calitp-staging-gtfs-rt-parsed",
    "calitp-staging-gtfs-rt-raw-v2",
    "calitp-staging-gtfs-rt-validation",
    "calitp-staging-gtfs-schedule-parsed",
    "calitp-staging-gtfs-schedule-parsed-hourly",
    "calitp-staging-gtfs-schedule-raw-v2",
    "calitp-staging-gtfs-schedule-unzipped",
    "calitp-staging-gtfs-schedule-unzipped-hourly",
    "calitp-staging-gtfs-schedule-validation",
    "calitp-staging-gtfs-schedule-validation-hourly",
    "calitp-staging-kuba",
    "calitp-staging-ntd-api-products",
    "calitp-staging-ntd-report-validation",
    "calitp-staging-ntd-xlsx-products-clean",
    "calitp-staging-ntd-xlsx-products-raw",
    "calitp-staging-payments-littlepay-parsed",
    "calitp-staging-payments-littlepay-parsed-v3",
    "calitp-staging-payments-littlepay-raw",
    "calitp-staging-payments-littlepay-raw-v3",
    "calitp-staging-publish",
    "calitp-staging-pytest",
    "calitp-staging-sentry",
    "calitp-staging-state-geoportal-scrape",
  ])
}

data "terraform_remote_state" "iam" {
  backend = "gcs"

  config = {
    bucket = "calitp-staging-gcp-components-tfstate"
    prefix = "cal-itp-data-infra-staging/iam"
  }
}
