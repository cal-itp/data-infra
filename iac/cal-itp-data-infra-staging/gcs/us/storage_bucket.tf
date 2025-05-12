resource "google_storage_bucket" "tfer--calitp-staging-data-analyses-portfolio" {
  default_event_based_hold    = "false"
  force_destroy               = "false"
  location                    = "US-WEST2"
  name                        = "calitp-staging-data-analyses-portfolio"
  project                     = "cal-itp-data-infra-staging"
  public_access_prevention    = "inherited"
  requester_pays              = "false"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = "false"
}

resource "google_storage_bucket" "tfer--calitp-staging-data-analyses-portfolio-draft" {
  default_event_based_hold    = "false"
  force_destroy               = "false"
  location                    = "US-WEST2"
  name                        = "calitp-staging-data-analyses-portfolio-draft"
  project                     = "cal-itp-data-infra-staging"
  public_access_prevention    = "inherited"
  requester_pays              = "false"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = "false"

  website {
    main_page_suffix = "index.html"
  }
}

resource "google_storage_bucket" "tfer--dataproc-staging-us-west2-473674835135-t87wkokr" {
  default_event_based_hold    = "false"
  force_destroy               = "false"
  location                    = "US-WEST2"
  name                        = "dataproc-staging-us-west2-473674835135-t87wkokr"
  project                     = "cal-itp-data-infra-staging"
  public_access_prevention    = "inherited"
  requester_pays              = "false"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = "false"
}

resource "google_storage_bucket" "tfer--dataproc-temp-us-west2-473674835135-yuzmmdyk" {
  default_event_based_hold = "false"
  force_destroy            = "false"

  lifecycle_rule {
    action {
      type = "Delete"
    }

    condition {
      age                        = "90"
      created_before             = ""
      days_since_custom_time     = "0"
      days_since_noncurrent_time = "0"
      num_newer_versions         = "0"
      with_state                 = "ANY"
    }
  }

  location                    = "US-WEST2"
  name                        = "dataproc-temp-us-west2-473674835135-yuzmmdyk"
  project                     = "cal-itp-data-infra-staging"
  public_access_prevention    = "inherited"
  requester_pays              = "false"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = "false"
}

resource "google_storage_bucket" "tfer--test-calitp-amplitude-benefits-events" {
  default_event_based_hold    = "false"
  force_destroy               = "false"
  location                    = "US-WEST2"
  name                        = "test-calitp-amplitude-benefits-events"
  project                     = "cal-itp-data-infra-staging"
  public_access_prevention    = "enforced"
  requester_pays              = "false"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"

  lifecycle_rule {
    action {
      type = "Delete"
    }

    condition {
      age                        = "30"
      created_before             = ""
      days_since_custom_time     = "0"
      days_since_noncurrent_time = "0"
      num_newer_versions         = "0"
      with_state                 = "ANY"
    }
  }
}

resource "google_storage_bucket" "tfer--calitp-staging-gcp-components-tfstate" {
  default_event_based_hold    = "false"
  force_destroy               = "false"
  location                    = "US"
  name                        = "calitp-staging-gcp-components-tfstate"
  project                     = "cal-itp-data-infra-staging"
  public_access_prevention    = "inherited"
  requester_pays              = "false"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "calitp-staging-dbt-artifacts" {
  default_event_based_hold    = "false"
  force_destroy               = "true"
  location                    = "US-WEST2"
  name                        = "calitp-staging-dbt-artifacts"
  project                     = "cal-itp-data-infra-staging"
  public_access_prevention    = "inherited"
  requester_pays              = "false"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "calitp-staging-dbt-docs" {
  default_event_based_hold    = "false"
  force_destroy               = "true"
  location                    = "US-WEST2"
  name                        = "calitp-staging-dbt-docs"
  project                     = "cal-itp-data-infra-staging"
  public_access_prevention    = "inherited"
  requester_pays              = "false"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"

  website {
    main_page_suffix = "index.html"
  }
}

resource "google_storage_bucket" "calitp-staging-composer" {
  default_event_based_hold    = "false"
  force_destroy               = "true"
  location                    = "US-WEST2"
  name                        = "calitp-staging-composer"
  project                     = "cal-itp-data-infra-staging"
  public_access_prevention    = "inherited"
  requester_pays              = "false"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"

  lifecycle {
    ignore_changes = [labels]
  }
}

resource "google_storage_bucket" "calitp-staging-aggregator-scraper" {
  default_event_based_hold    = "false"
  force_destroy               = "true"
  location                    = "US-WEST2"
  name                        = "calitp-staging-aggregator-scraper"
  project                     = "cal-itp-data-infra-staging"
  public_access_prevention    = "inherited"
  requester_pays              = "false"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "calitp-staging-airtable" {
  default_event_based_hold    = "false"
  force_destroy               = "true"
  location                    = "US-WEST2"
  name                        = "calitp-staging-airtable"
  project                     = "cal-itp-data-infra-staging"
  public_access_prevention    = "inherited"
  requester_pays              = "false"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "calitp-staging-elavon-parsed" {
  default_event_based_hold    = "false"
  force_destroy               = "true"
  location                    = "US-WEST2"
  name                        = "calitp-staging-elavon-parsed"
  project                     = "cal-itp-data-infra-staging"
  public_access_prevention    = "inherited"
  requester_pays              = "false"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "calitp-staging-elavon-raw" {
  default_event_based_hold    = "false"
  force_destroy               = "true"
  location                    = "US-WEST2"
  name                        = "calitp-staging-elavon-raw"
  project                     = "cal-itp-data-infra-staging"
  public_access_prevention    = "inherited"
  requester_pays              = "false"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "calitp-staging-gtfs-download-config" {
  default_event_based_hold    = "false"
  force_destroy               = "true"
  location                    = "US-WEST2"
  name                        = "calitp-staging-gtfs-download-config"
  project                     = "cal-itp-data-infra-staging"
  public_access_prevention    = "inherited"
  requester_pays              = "false"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "calitp-staging-gtfs-rt-parsed" {
  default_event_based_hold    = "false"
  force_destroy               = "true"
  location                    = "US-WEST2"
  name                        = "calitp-staging-gtfs-rt-parsed"
  project                     = "cal-itp-data-infra-staging"
  public_access_prevention    = "inherited"
  requester_pays              = "false"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "calitp-staging-gtfs-rt-raw-v2" {
  default_event_based_hold    = "false"
  force_destroy               = "true"
  location                    = "US-WEST2"
  name                        = "calitp-staging-gtfs-rt-raw-v2"
  project                     = "cal-itp-data-infra-staging"
  public_access_prevention    = "inherited"
  requester_pays              = "false"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "calitp-staging-gtfs-rt-validation" {
  default_event_based_hold    = "false"
  force_destroy               = "true"
  location                    = "US-WEST2"
  name                        = "calitp-staging-gtfs-rt-validation"
  project                     = "cal-itp-data-infra-staging"
  public_access_prevention    = "inherited"
  requester_pays              = "false"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "calitp-staging-gtfs-schedule-parsed" {
  default_event_based_hold    = "false"
  force_destroy               = "true"
  location                    = "US-WEST2"
  name                        = "calitp-staging-gtfs-schedule-parsed"
  project                     = "cal-itp-data-infra-staging"
  public_access_prevention    = "inherited"
  requester_pays              = "false"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "calitp-staging-gtfs-schedule-parsed-hourly" {
  default_event_based_hold    = "false"
  force_destroy               = "true"
  location                    = "US-WEST2"
  name                        = "calitp-staging-gtfs-schedule-parsed-hourly"
  project                     = "cal-itp-data-infra-staging"
  public_access_prevention    = "inherited"
  requester_pays              = "false"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "calitp-staging-gtfs-schedule-raw-v2" {
  default_event_based_hold    = "false"
  force_destroy               = "true"
  location                    = "US-WEST2"
  name                        = "calitp-staging-gtfs-schedule-raw-v2"
  project                     = "cal-itp-data-infra-staging"
  public_access_prevention    = "inherited"
  requester_pays              = "false"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "calitp-staging-gtfs-schedule-unzipped" {
  default_event_based_hold    = "false"
  force_destroy               = "true"
  location                    = "US-WEST2"
  name                        = "calitp-staging-gtfs-schedule-unzipped"
  project                     = "cal-itp-data-infra-staging"
  public_access_prevention    = "inherited"
  requester_pays              = "false"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "calitp-staging-gtfs-schedule-unzipped-hourly" {
  default_event_based_hold    = "false"
  force_destroy               = "true"
  location                    = "US-WEST2"
  name                        = "calitp-staging-gtfs-schedule-unzipped-hourly"
  project                     = "cal-itp-data-infra-staging"
  public_access_prevention    = "inherited"
  requester_pays              = "false"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "calitp-staging-gtfs-schedule-validation" {
  default_event_based_hold    = "false"
  force_destroy               = "true"
  location                    = "US-WEST2"
  name                        = "calitp-staging-gtfs-schedule-validation"
  project                     = "cal-itp-data-infra-staging"
  public_access_prevention    = "inherited"
  requester_pays              = "false"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "calitp-staging-gtfs-schedule-validation-hourly" {
  default_event_based_hold    = "false"
  force_destroy               = "true"
  location                    = "US-WEST2"
  name                        = "calitp-staging-gtfs-schedule-validation-hourly"
  project                     = "cal-itp-data-infra-staging"
  public_access_prevention    = "inherited"
  requester_pays              = "false"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "calitp-staging-ntd-api-products" {
  default_event_based_hold    = "false"
  force_destroy               = "true"
  location                    = "US-WEST2"
  name                        = "calitp-staging-ntd-api-products"
  project                     = "cal-itp-data-infra-staging"
  public_access_prevention    = "inherited"
  requester_pays              = "false"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "calitp-staging-ntd-xlsx-products-clean" {
  default_event_based_hold    = "false"
  force_destroy               = "true"
  location                    = "US-WEST2"
  name                        = "calitp-staging-ntd-xlsx-products-clean"
  project                     = "cal-itp-data-infra-staging"
  public_access_prevention    = "inherited"
  requester_pays              = "false"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "calitp-staging-ntd-xlsx-products-raw" {
  default_event_based_hold    = "false"
  force_destroy               = "true"
  location                    = "US-WEST2"
  name                        = "calitp-staging-ntd-xlsx-products-raw"
  project                     = "cal-itp-data-infra-staging"
  public_access_prevention    = "inherited"
  requester_pays              = "false"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "calitp-staging-payments-littlepay-parsed" {
  default_event_based_hold    = "false"
  force_destroy               = "true"
  location                    = "US-WEST2"
  name                        = "calitp-staging-payments-littlepay-parsed"
  project                     = "cal-itp-data-infra-staging"
  public_access_prevention    = "inherited"
  requester_pays              = "false"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "calitp-staging-payments-littlepay-parsed-v3" {
  default_event_based_hold    = "false"
  force_destroy               = "true"
  location                    = "US-WEST2"
  name                        = "calitp-staging-payments-littlepay-parsed-v3"
  project                     = "cal-itp-data-infra-staging"
  public_access_prevention    = "inherited"
  requester_pays              = "false"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "calitp-staging-payments-littlepay-raw" {
  default_event_based_hold    = "false"
  force_destroy               = "true"
  location                    = "US-WEST2"
  name                        = "calitp-staging-payments-littlepay-raw"
  project                     = "cal-itp-data-infra-staging"
  public_access_prevention    = "inherited"
  requester_pays              = "false"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "calitp-staging-payments-littlepay-raw-v3" {
  default_event_based_hold    = "false"
  force_destroy               = "true"
  location                    = "US-WEST2"
  name                        = "calitp-staging-payments-littlepay-raw-v3"
  project                     = "cal-itp-data-infra-staging"
  public_access_prevention    = "inherited"
  requester_pays              = "false"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "calitp-staging-publish" {
  default_event_based_hold    = "false"
  force_destroy               = "true"
  location                    = "US-WEST2"
  name                        = "calitp-staging-publish"
  project                     = "cal-itp-data-infra-staging"
  public_access_prevention    = "inherited"
  requester_pays              = "false"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "calitp-staging-sentry" {
  default_event_based_hold    = "false"
  force_destroy               = "true"
  location                    = "US-WEST2"
  name                        = "calitp-staging-sentry"
  project                     = "cal-itp-data-infra-staging"
  public_access_prevention    = "inherited"
  requester_pays              = "false"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "calitp-staging-state-geoportal-scrape" {
  default_event_based_hold    = "false"
  force_destroy               = "true"
  location                    = "US-WEST2"
  name                        = "calitp-staging-state-geoportal-scrape"
  project                     = "cal-itp-data-infra-staging"
  public_access_prevention    = "inherited"
  requester_pays              = "false"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "calitp-staging-gtfs-download-config-test" {
  default_event_based_hold    = "false"
  force_destroy               = "true"
  location                    = "US-WEST2"
  name                        = "calitp-staging-gtfs-download-config-test"
  project                     = "cal-itp-data-infra-staging"
  public_access_prevention    = "inherited"
  requester_pays              = "false"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}
