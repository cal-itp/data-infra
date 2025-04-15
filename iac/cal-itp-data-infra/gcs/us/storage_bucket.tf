resource "google_storage_bucket" "tfer--analysis-output-models" {
  default_event_based_hold = "false"
  force_destroy            = "false"

  lifecycle_rule {
    action {
      type = "Delete"
    }

    condition {
      age                        = "0"
      created_before             = ""
      days_since_custom_time     = "0"
      days_since_noncurrent_time = "0"
      num_newer_versions         = "2"
      with_state                 = "ARCHIVED"
    }
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }

    condition {
      age                        = "0"
      created_before             = ""
      days_since_custom_time     = "0"
      days_since_noncurrent_time = "7"
      num_newer_versions         = "0"
      with_state                 = "ANY"
    }
  }

  location                    = "US-WEST2"
  name                        = "analysis-output-models"
  project                     = "cal-itp-data-infra"
  public_access_prevention    = "enforced"
  requester_pays              = "false"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"

  versioning {
    enabled = "true"
  }
}

resource "google_storage_bucket" "tfer--artifacts-002E-cal-itp-data-infra-002E-appspot-002E-com" {
  default_event_based_hold    = "false"
  force_destroy               = "false"
  location                    = "US"
  name                        = "artifacts.cal-itp-data-infra.appspot.com"
  project                     = "cal-itp-data-infra"
  public_access_prevention    = "inherited"
  requester_pays              = "false"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = "false"
}

resource "google_storage_bucket" "tfer--cal-itp-data-infra-002E-appspot-002E-com" {
  default_event_based_hold    = "false"
  force_destroy               = "false"
  location                    = "US-WEST2"
  name                        = "cal-itp-data-infra.appspot.com"
  project                     = "cal-itp-data-infra"
  public_access_prevention    = "inherited"
  requester_pays              = "false"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = "false"
}

resource "google_storage_bucket" "tfer--calitp-aggregator-scraper" {
  default_event_based_hold    = "false"
  force_destroy               = "false"
  location                    = "US-WEST2"
  name                        = "calitp-aggregator-scraper"
  project                     = "cal-itp-data-infra"
  public_access_prevention    = "enforced"
  requester_pays              = "false"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--calitp-airtable" {
  default_event_based_hold = "false"
  force_destroy            = "false"

  lifecycle_rule {
    action {
      type = "Delete"
    }

    condition {
      age                        = "0"
      created_before             = ""
      days_since_custom_time     = "0"
      days_since_noncurrent_time = "0"
      num_newer_versions         = "2"
      with_state                 = "ARCHIVED"
    }
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }

    condition {
      age                        = "0"
      created_before             = ""
      days_since_custom_time     = "0"
      days_since_noncurrent_time = "7"
      num_newer_versions         = "0"
      with_state                 = "ANY"
    }
  }

  location                 = "US-WEST2"
  name                     = "calitp-airtable"
  project                  = "cal-itp-data-infra"
  public_access_prevention = "inherited"
  requester_pays           = "false"

  retention_policy {
    is_locked        = "false"
    retention_period = "31557600"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"

  versioning {
    enabled = "false"
  }
}

resource "google_storage_bucket" "tfer--calitp-amplitude-benefits-events" {
  default_event_based_hold    = "false"
  force_destroy               = "false"
  location                    = "US-WEST2"
  name                        = "calitp-amplitude-benefits-events"
  project                     = "cal-itp-data-infra"
  public_access_prevention    = "enforced"
  requester_pays              = "false"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--calitp-analytics-data" {
  default_event_based_hold    = "false"
  force_destroy               = "false"
  location                    = "US-WEST2"
  name                        = "calitp-analytics-data"
  project                     = "cal-itp-data-infra"
  public_access_prevention    = "inherited"
  requester_pays              = "false"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"

  versioning {
    enabled = "true"
  }
}

resource "google_storage_bucket" "tfer--calitp-backups-grafana" {
  default_event_based_hold    = "false"
  force_destroy               = "false"
  location                    = "US-WEST2"
  name                        = "calitp-backups-grafana"
  project                     = "cal-itp-data-infra"
  public_access_prevention    = "enforced"
  requester_pays              = "false"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--calitp-backups-metabase" {
  default_event_based_hold    = "false"
  force_destroy               = "false"
  location                    = "US-WEST1"
  name                        = "calitp-backups-metabase"
  project                     = "cal-itp-data-infra"
  public_access_prevention    = "inherited"
  requester_pays              = "false"
  storage_class               = "NEARLINE"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--calitp-backups-sentry" {
  default_event_based_hold    = "false"
  force_destroy               = "false"
  location                    = "US-WEST2"
  name                        = "calitp-backups-sentry"
  project                     = "cal-itp-data-infra"
  public_access_prevention    = "enforced"
  requester_pays              = "false"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--calitp-backups-test" {
  default_event_based_hold    = "false"
  force_destroy               = "false"
  location                    = "US-WEST2"
  name                        = "calitp-backups-test"
  project                     = "cal-itp-data-infra"
  public_access_prevention    = "enforced"
  requester_pays              = "false"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--calitp-ci-artifacts" {
  default_event_based_hold    = "false"
  force_destroy               = "false"
  location                    = "US-WEST2"
  name                        = "calitp-ci-artifacts"
  project                     = "cal-itp-data-infra"
  public_access_prevention    = "enforced"
  requester_pays              = "false"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--calitp-dbt-artifacts" {
  default_event_based_hold    = "false"
  force_destroy               = "false"
  location                    = "US-WEST2"
  name                        = "calitp-dbt-artifacts"
  project                     = "cal-itp-data-infra"
  public_access_prevention    = "enforced"
  requester_pays              = "false"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--calitp-dbt-python-models" {
  default_event_based_hold    = "false"
  force_destroy               = "false"
  location                    = "US-WEST2"
  name                        = "calitp-dbt-python-models"
  project                     = "cal-itp-data-infra"
  public_access_prevention    = "enforced"
  requester_pays              = "false"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--calitp-elavon-parsed" {
  default_event_based_hold    = "false"
  force_destroy               = "false"
  location                    = "US-WEST2"
  name                        = "calitp-elavon-parsed"
  project                     = "cal-itp-data-infra"
  public_access_prevention    = "enforced"
  requester_pays              = "false"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--calitp-elavon-raw" {
  default_event_based_hold    = "false"
  force_destroy               = "false"
  location                    = "US-WEST2"
  name                        = "calitp-elavon-raw"
  project                     = "cal-itp-data-infra"
  public_access_prevention    = "enforced"
  requester_pays              = "false"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--calitp-gtfs-download-config" {
  default_event_based_hold = "false"
  force_destroy            = "false"
  location                 = "US-WEST2"
  name                     = "calitp-gtfs-download-config"
  project                  = "cal-itp-data-infra"
  public_access_prevention = "inherited"
  requester_pays           = "false"

  retention_policy {
    is_locked        = "false"
    retention_period = "31557600"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--calitp-gtfs-rt-parsed" {
  default_event_based_hold    = "false"
  force_destroy               = "false"
  location                    = "US-WEST2"
  name                        = "calitp-gtfs-rt-parsed"
  project                     = "cal-itp-data-infra"
  public_access_prevention    = "inherited"
  requester_pays              = "false"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--calitp-gtfs-rt-raw-deprecated" {
  default_event_based_hold = "false"
  force_destroy            = "false"

  labels = {
    deprecated = "true"
  }

  location                    = "US-WEST2"
  name                        = "calitp-gtfs-rt-raw-deprecated"
  project                     = "cal-itp-data-infra"
  public_access_prevention    = "enforced"
  requester_pays              = "false"
  storage_class               = "ARCHIVE"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--calitp-gtfs-rt-raw-v2" {
  default_event_based_hold = "false"
  force_destroy            = "false"
  location                 = "US-WEST2"
  name                     = "calitp-gtfs-rt-raw-v2"
  project                  = "cal-itp-data-infra"
  public_access_prevention = "inherited"
  requester_pays           = "false"

  retention_policy {
    is_locked        = "false"
    retention_period = "31557600"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--calitp-gtfs-rt-validation" {
  default_event_based_hold    = "false"
  force_destroy               = "false"
  location                    = "US-WEST2"
  name                        = "calitp-gtfs-rt-validation"
  project                     = "cal-itp-data-infra"
  public_access_prevention    = "inherited"
  requester_pays              = "false"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--calitp-gtfs-schedule-parsed" {
  default_event_based_hold    = "false"
  force_destroy               = "false"
  location                    = "US-WEST2"
  name                        = "calitp-gtfs-schedule-parsed"
  project                     = "cal-itp-data-infra"
  public_access_prevention    = "inherited"
  requester_pays              = "false"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--calitp-gtfs-schedule-parsed-hourly" {
  default_event_based_hold    = "false"
  force_destroy               = "false"
  location                    = "US-WEST2"
  name                        = "calitp-gtfs-schedule-parsed-hourly"
  project                     = "cal-itp-data-infra"
  public_access_prevention    = "enforced"
  requester_pays              = "false"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--calitp-gtfs-schedule-raw-v2" {
  default_event_based_hold = "false"
  force_destroy            = "false"
  location                 = "US-WEST2"
  name                     = "calitp-gtfs-schedule-raw-v2"
  project                  = "cal-itp-data-infra"
  public_access_prevention = "inherited"
  requester_pays           = "false"

  retention_policy {
    is_locked        = "false"
    retention_period = "31557600"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--calitp-gtfs-schedule-unzipped" {
  default_event_based_hold    = "false"
  force_destroy               = "false"
  location                    = "US-WEST2"
  name                        = "calitp-gtfs-schedule-unzipped"
  project                     = "cal-itp-data-infra"
  public_access_prevention    = "inherited"
  requester_pays              = "false"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--calitp-gtfs-schedule-unzipped-hourly" {
  default_event_based_hold    = "false"
  force_destroy               = "false"
  location                    = "US-WEST2"
  name                        = "calitp-gtfs-schedule-unzipped-hourly"
  project                     = "cal-itp-data-infra"
  public_access_prevention    = "enforced"
  requester_pays              = "false"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--calitp-gtfs-schedule-validation" {
  default_event_based_hold    = "false"
  force_destroy               = "false"
  location                    = "US-WEST2"
  name                        = "calitp-gtfs-schedule-validation"
  project                     = "cal-itp-data-infra"
  public_access_prevention    = "inherited"
  requester_pays              = "false"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--calitp-gtfs-schedule-validation-hourly" {
  default_event_based_hold    = "false"
  force_destroy               = "false"
  location                    = "US-WEST2"
  name                        = "calitp-gtfs-schedule-validation-hourly"
  project                     = "cal-itp-data-infra"
  public_access_prevention    = "enforced"
  requester_pays              = "false"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--calitp-map-tiles" {
  cors {
    max_age_seconds = "300"
    method          = ["GET", "HEAD"]
    origin          = ["*"]
    response_header = ["range", "etag"]
  }

  default_event_based_hold    = "false"
  force_destroy               = "false"
  location                    = "US-WEST2"
  name                        = "calitp-map-tiles"
  project                     = "cal-itp-data-infra"
  public_access_prevention    = "inherited"
  requester_pays              = "false"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--calitp-metabase-data-public" {
  default_event_based_hold    = "false"
  force_destroy               = "false"
  location                    = "US-WEST2"
  name                        = "calitp-metabase-data-public"
  project                     = "cal-itp-data-infra"
  public_access_prevention    = "inherited"
  requester_pays              = "false"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = "false"
}

resource "google_storage_bucket" "tfer--calitp-ntd-api-products" {
  default_event_based_hold    = "false"
  force_destroy               = "false"
  location                    = "US"
  name                        = "calitp-ntd-api-products"
  project                     = "cal-itp-data-infra"
  public_access_prevention    = "enforced"
  requester_pays              = "false"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--calitp-ntd-report-validation" {
  default_event_based_hold    = "false"
  force_destroy               = "false"
  location                    = "US-WEST2"
  name                        = "calitp-ntd-report-validation"
  project                     = "cal-itp-data-infra"
  public_access_prevention    = "enforced"
  requester_pays              = "false"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--calitp-ntd-xlsx-products-clean" {
  default_event_based_hold    = "false"
  force_destroy               = "false"
  location                    = "US"
  name                        = "calitp-ntd-xlsx-products-clean"
  project                     = "cal-itp-data-infra"
  public_access_prevention    = "enforced"
  requester_pays              = "false"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--calitp-ntd-xlsx-products-raw" {
  default_event_based_hold    = "false"
  force_destroy               = "false"
  location                    = "US"
  name                        = "calitp-ntd-xlsx-products-raw"
  project                     = "cal-itp-data-infra"
  public_access_prevention    = "enforced"
  requester_pays              = "false"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--calitp-payments-littlepay-parsed" {
  default_event_based_hold    = "false"
  force_destroy               = "false"
  location                    = "US-WEST2"
  name                        = "calitp-payments-littlepay-parsed"
  project                     = "cal-itp-data-infra"
  public_access_prevention    = "enforced"
  requester_pays              = "false"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--calitp-payments-littlepay-raw" {
  default_event_based_hold = "false"
  force_destroy            = "false"
  location                 = "US-WEST2"
  name                     = "calitp-payments-littlepay-raw"
  project                  = "cal-itp-data-infra"
  public_access_prevention = "enforced"
  requester_pays           = "false"

  retention_policy {
    is_locked        = "false"
    retention_period = "31557600"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--calitp-prod-gcp-components-tfstate" {
  default_event_based_hold    = "false"
  force_destroy               = "false"
  location                    = "US"
  name                        = "calitp-prod-gcp-components-tfstate"
  project                     = "cal-itp-data-infra"
  public_access_prevention    = "inherited"
  requester_pays              = "false"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--calitp-publish" {
  default_event_based_hold    = "false"
  force_destroy               = "false"
  location                    = "US-WEST2"
  name                        = "calitp-publish"
  project                     = "cal-itp-data-infra"
  public_access_prevention    = "inherited"
  requester_pays              = "false"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--calitp-publish-data-analysis" {
  default_event_based_hold    = "false"
  force_destroy               = "false"
  location                    = "US-WEST2"
  name                        = "calitp-publish-data-analysis"
  project                     = "cal-itp-data-infra"
  public_access_prevention    = "inherited"
  requester_pays              = "false"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--calitp-reports-data" {
  default_event_based_hold    = "false"
  force_destroy               = "false"
  location                    = "US-WEST2"
  name                        = "calitp-reports-data"
  project                     = "cal-itp-data-infra"
  public_access_prevention    = "enforced"
  requester_pays              = "false"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--calitp-state-geoportal-scrape" {
  default_event_based_hold    = "false"
  force_destroy               = "false"
  location                    = "US"
  name                        = "calitp-state-geoportal-scrape"
  project                     = "cal-itp-data-infra"
  public_access_prevention    = "enforced"
  requester_pays              = "false"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--calitp-state-highway-network-stops" {
  default_event_based_hold    = "false"
  force_destroy               = "false"
  location                    = "US"
  name                        = "calitp-state-highway-network-stops"
  project                     = "cal-itp-data-infra"
  public_access_prevention    = "enforced"
  requester_pays              = "false"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--dataproc-staging-us-west2-1005246706141-sfgmtgyp" {
  default_event_based_hold    = "false"
  force_destroy               = "false"
  location                    = "US-WEST2"
  name                        = "dataproc-staging-us-west2-1005246706141-sfgmtgyp"
  project                     = "cal-itp-data-infra"
  public_access_prevention    = "inherited"
  requester_pays              = "false"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = "false"
}

resource "google_storage_bucket" "tfer--dataproc-temp-us-west2-1005246706141-x9mtxbwg" {
  default_event_based_hold = "false"
  force_destroy            = "false"

  lifecycle {
    ignore_changes = [labels]
  }

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
  name                        = "dataproc-temp-us-west2-1005246706141-x9mtxbwg"
  project                     = "cal-itp-data-infra"
  public_access_prevention    = "inherited"
  requester_pays              = "false"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = "false"
}

resource "google_storage_bucket" "tfer--dev-calitp-aggregator-scraper" {
  default_event_based_hold    = "false"
  force_destroy               = "false"
  location                    = "US-WEST2"
  name                        = "dev-calitp-aggregator-scraper"
  project                     = "cal-itp-data-infra"
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

resource "google_storage_bucket" "tfer--dev-calitp-gtfs-rt-raw" {
  default_event_based_hold    = "false"
  force_destroy               = "false"
  location                    = "US-WEST2"
  name                        = "dev-calitp-gtfs-rt-raw"
  project                     = "cal-itp-data-infra"
  public_access_prevention    = "inherited"
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

resource "google_storage_bucket" "tfer--dev-calitp-test-sandbox" {
  default_event_based_hold = "false"
  force_destroy            = "false"

  lifecycle_rule {
    action {
      type = "Delete"
    }

    condition {
      age                        = "1"
      created_before             = ""
      days_since_custom_time     = "0"
      days_since_noncurrent_time = "0"
      num_newer_versions         = "0"
      with_state                 = "ANY"
    }
  }

  location                    = "US-WEST2"
  name                        = "dev-calitp-test-sandbox"
  project                     = "cal-itp-data-infra"
  public_access_prevention    = "enforced"
  requester_pays              = "false"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--export-ysjqwvyxc4ti3jmahojq" {
  default_event_based_hold    = "false"
  force_destroy               = "false"
  location                    = "US"
  name                        = "export-ysjqwvyxc4ti3jmahojq"
  project                     = "cal-itp-data-infra"
  public_access_prevention    = "inherited"
  requester_pays              = "false"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = "false"
}

resource "google_storage_bucket" "tfer--gtfs-data" {
  default_event_based_hold    = "false"
  force_destroy               = "false"
  location                    = "US-WEST2"
  name                        = "gtfs-data"
  project                     = "cal-itp-data-infra"
  public_access_prevention    = "inherited"
  requester_pays              = "false"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = "false"
}

resource "google_storage_bucket" "tfer--gtfs-data-reports" {
  autoclass {
    enabled = "true"
  }

  default_event_based_hold    = "false"
  force_destroy               = "false"
  location                    = "US-WEST2"
  name                        = "gtfs-data-reports"
  project                     = "cal-itp-data-infra"
  public_access_prevention    = "enforced"
  requester_pays              = "false"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--gtfs-data-test" {
  default_event_based_hold    = "false"
  force_destroy               = "false"
  location                    = "US-WEST2"
  name                        = "gtfs-data-test"
  project                     = "cal-itp-data-infra"
  public_access_prevention    = "inherited"
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

resource "google_storage_bucket" "tfer--gtfs-data-test-reports" {
  autoclass {
    enabled = "true"
  }

  default_event_based_hold    = "false"
  force_destroy               = "false"
  location                    = "US-WEST2"
  name                        = "gtfs-data-test-reports"
  project                     = "cal-itp-data-infra"
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

resource "google_storage_bucket" "tfer--gtfs-schedule-backfill-test" {
  default_event_based_hold = "false"
  force_destroy            = "false"

  lifecycle_rule {
    action {
      type = "Delete"
    }

    condition {
      age                        = "0"
      created_before             = ""
      days_since_custom_time     = "0"
      days_since_noncurrent_time = "0"
      num_newer_versions         = "0"
      with_state                 = "ANY"
    }
  }

  location                    = "US-WEST2"
  name                        = "gtfs-schedule-backfill-test"
  project                     = "cal-itp-data-infra"
  public_access_prevention    = "enforced"
  requester_pays              = "false"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--gtfs-schedule-backfill-test-deprecated" {
  default_event_based_hold = "false"
  force_destroy            = "false"

  lifecycle_rule {
    action {
      type = "Delete"
    }

    condition {
      age                        = "0"
      created_before             = ""
      days_since_custom_time     = "0"
      days_since_noncurrent_time = "0"
      num_newer_versions         = "0"
      with_state                 = "ANY"
    }
  }

  location                    = "US-WEST2"
  name                        = "gtfs-schedule-backfill-test-deprecated"
  project                     = "cal-itp-data-infra"
  public_access_prevention    = "enforced"
  requester_pays              = "false"
  storage_class               = "ARCHIVE"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--littlepay-data-extract-prod" {
  default_event_based_hold    = "false"
  force_destroy               = "false"
  location                    = "US-WEST2"
  name                        = "littlepay-data-extract-prod"
  project                     = "cal-itp-data-infra"
  public_access_prevention    = "inherited"
  requester_pays              = "false"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--rt-parsed" {
  default_event_based_hold    = "false"
  force_destroy               = "false"
  location                    = "US-WEST2"
  name                        = "rt-parsed"
  project                     = "cal-itp-data-infra"
  public_access_prevention    = "inherited"
  requester_pays              = "false"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--rt-parsed-deprecated" {
  default_event_based_hold = "false"
  force_destroy            = "false"

  labels = {
    deprecated = ""
  }

  location                    = "US-WEST2"
  name                        = "rt-parsed-deprecated"
  project                     = "cal-itp-data-infra"
  public_access_prevention    = "enforced"
  requester_pays              = "false"
  storage_class               = "ARCHIVE"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--staging-002E-cal-itp-data-infra-002E-appspot-002E-com" {
  default_event_based_hold = "false"
  force_destroy            = "false"

  lifecycle_rule {
    action {
      type = "Delete"
    }

    condition {
      age                        = "15"
      created_before             = ""
      days_since_custom_time     = "0"
      days_since_noncurrent_time = "0"
      num_newer_versions         = "0"
      with_state                 = "ANY"
    }
  }

  location                    = "US-WEST2"
  name                        = "staging.cal-itp-data-infra.appspot.com"
  project                     = "cal-itp-data-infra"
  public_access_prevention    = "inherited"
  requester_pays              = "false"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = "false"
}

resource "google_storage_bucket" "tfer--test-calitp-aggregator-scraper" {
  default_event_based_hold    = "false"
  force_destroy               = "false"
  location                    = "US-WEST2"
  name                        = "test-calitp-aggregator-scraper"
  project                     = "cal-itp-data-infra"
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

resource "google_storage_bucket" "tfer--test-calitp-airtable" {
  default_event_based_hold    = "false"
  force_destroy               = "false"
  location                    = "US-WEST2"
  name                        = "test-calitp-airtable"
  project                     = "cal-itp-data-infra"
  public_access_prevention    = "inherited"
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

resource "google_storage_bucket" "tfer--test-calitp-dbt-artifacts" {
  default_event_based_hold    = "false"
  force_destroy               = "false"
  location                    = "US-WEST2"
  name                        = "test-calitp-dbt-artifacts"
  project                     = "cal-itp-data-infra"
  public_access_prevention    = "inherited"
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

resource "google_storage_bucket" "tfer--test-calitp-dbt-python-models" {
  default_event_based_hold    = "false"
  force_destroy               = "false"
  location                    = "US-WEST2"
  name                        = "test-calitp-dbt-python-models"
  project                     = "cal-itp-data-infra"
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

resource "google_storage_bucket" "tfer--test-calitp-elavon" {
  default_event_based_hold = "false"
  force_destroy            = "false"

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

  location                    = "US-WEST2"
  name                        = "test-calitp-elavon"
  project                     = "cal-itp-data-infra"
  public_access_prevention    = "enforced"
  requester_pays              = "false"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"

  versioning {
    enabled = "false"
  }
}

resource "google_storage_bucket" "tfer--test-calitp-elavon-parsed" {
  default_event_based_hold    = "false"
  force_destroy               = "false"
  location                    = "US-WEST2"
  name                        = "test-calitp-elavon-parsed"
  project                     = "cal-itp-data-infra"
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

resource "google_storage_bucket" "tfer--test-calitp-elavon-raw" {
  default_event_based_hold    = "false"
  force_destroy               = "false"
  location                    = "US-WEST2"
  name                        = "test-calitp-elavon-raw"
  project                     = "cal-itp-data-infra"
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

resource "google_storage_bucket" "tfer--test-calitp-gtfs-config" {
  default_event_based_hold    = "false"
  force_destroy               = "false"
  location                    = "US-WEST2"
  name                        = "test-calitp-gtfs-config"
  project                     = "cal-itp-data-infra"
  public_access_prevention    = "inherited"
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

resource "google_storage_bucket" "tfer--test-calitp-gtfs-download-config" {
  default_event_based_hold    = "false"
  force_destroy               = "false"
  location                    = "US-WEST2"
  name                        = "test-calitp-gtfs-download-config"
  project                     = "cal-itp-data-infra"
  public_access_prevention    = "inherited"
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

resource "google_storage_bucket" "tfer--test-calitp-gtfs-raw" {
  default_event_based_hold    = "false"
  force_destroy               = "false"
  location                    = "US-WEST2"
  name                        = "test-calitp-gtfs-raw"
  project                     = "cal-itp-data-infra"
  public_access_prevention    = "inherited"
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

resource "google_storage_bucket" "tfer--test-calitp-gtfs-rt-parsed" {
  default_event_based_hold    = "false"
  force_destroy               = "false"
  location                    = "US-WEST2"
  name                        = "test-calitp-gtfs-rt-parsed"
  project                     = "cal-itp-data-infra"
  public_access_prevention    = "inherited"
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

resource "google_storage_bucket" "tfer--test-calitp-gtfs-rt-raw" {
  default_event_based_hold    = "false"
  force_destroy               = "false"
  location                    = "US-WEST2"
  name                        = "test-calitp-gtfs-rt-raw"
  project                     = "cal-itp-data-infra"
  public_access_prevention    = "inherited"
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

resource "google_storage_bucket" "tfer--test-calitp-gtfs-rt-raw-v2" {
  default_event_based_hold    = "false"
  force_destroy               = "false"
  location                    = "US-WEST2"
  name                        = "test-calitp-gtfs-rt-raw-v2"
  project                     = "cal-itp-data-infra"
  public_access_prevention    = "inherited"
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

resource "google_storage_bucket" "tfer--test-calitp-gtfs-rt-validation" {
  default_event_based_hold    = "false"
  force_destroy               = "false"
  location                    = "US-WEST2"
  name                        = "test-calitp-gtfs-rt-validation"
  project                     = "cal-itp-data-infra"
  public_access_prevention    = "inherited"
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

resource "google_storage_bucket" "tfer--test-calitp-gtfs-schedule-parsed" {
  default_event_based_hold    = "false"
  force_destroy               = "false"
  location                    = "US-WEST2"
  name                        = "test-calitp-gtfs-schedule-parsed"
  project                     = "cal-itp-data-infra"
  public_access_prevention    = "inherited"
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

resource "google_storage_bucket" "tfer--test-calitp-gtfs-schedule-parsed-hourly" {
  default_event_based_hold    = "false"
  force_destroy               = "false"
  location                    = "US-WEST2"
  name                        = "test-calitp-gtfs-schedule-parsed-hourly"
  project                     = "cal-itp-data-infra"
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

resource "google_storage_bucket" "tfer--test-calitp-gtfs-schedule-processed" {
  default_event_based_hold    = "false"
  force_destroy               = "false"
  location                    = "US-WEST2"
  name                        = "test-calitp-gtfs-schedule-processed"
  project                     = "cal-itp-data-infra"
  public_access_prevention    = "inherited"
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

resource "google_storage_bucket" "tfer--test-calitp-gtfs-schedule-raw" {
  default_event_based_hold    = "false"
  force_destroy               = "false"
  location                    = "US-WEST2"
  name                        = "test-calitp-gtfs-schedule-raw"
  project                     = "cal-itp-data-infra"
  public_access_prevention    = "inherited"
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

resource "google_storage_bucket" "tfer--test-calitp-gtfs-schedule-raw-v2" {
  default_event_based_hold    = "false"
  force_destroy               = "false"
  location                    = "US-WEST2"
  name                        = "test-calitp-gtfs-schedule-raw-v2"
  project                     = "cal-itp-data-infra"
  public_access_prevention    = "inherited"
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

resource "google_storage_bucket" "tfer--test-calitp-gtfs-schedule-raw-v2-backfill-test" {
  default_event_based_hold    = "false"
  force_destroy               = "false"
  location                    = "US-WEST2"
  name                        = "test-calitp-gtfs-schedule-raw-v2-backfill-test"
  project                     = "cal-itp-data-infra"
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

resource "google_storage_bucket" "tfer--test-calitp-gtfs-schedule-unzipped" {
  default_event_based_hold    = "false"
  force_destroy               = "false"
  location                    = "US-WEST2"
  name                        = "test-calitp-gtfs-schedule-unzipped"
  project                     = "cal-itp-data-infra"
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

resource "google_storage_bucket" "tfer--test-calitp-gtfs-schedule-unzipped-hourly" {
  default_event_based_hold    = "false"
  force_destroy               = "false"
  location                    = "US-WEST2"
  name                        = "test-calitp-gtfs-schedule-unzipped-hourly"
  project                     = "cal-itp-data-infra"
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

resource "google_storage_bucket" "tfer--test-calitp-gtfs-schedule-validation" {
  default_event_based_hold    = "false"
  force_destroy               = "false"
  location                    = "US-WEST2"
  name                        = "test-calitp-gtfs-schedule-validation"
  project                     = "cal-itp-data-infra"
  public_access_prevention    = "inherited"
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

resource "google_storage_bucket" "tfer--test-calitp-gtfs-schedule-validation-hourly" {
  default_event_based_hold    = "false"
  force_destroy               = "false"
  location                    = "US-WEST2"
  name                        = "test-calitp-gtfs-schedule-validation-hourly"
  project                     = "cal-itp-data-infra"
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

resource "google_storage_bucket" "tfer--test-calitp-ntd-api-products" {
  default_event_based_hold    = "false"
  force_destroy               = "false"
  location                    = "US"
  name                        = "test-calitp-ntd-api-products"
  project                     = "cal-itp-data-infra"
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

resource "google_storage_bucket" "tfer--test-calitp-ntd-report-validation" {
  default_event_based_hold    = "false"
  force_destroy               = "false"
  location                    = "US-WEST2"
  name                        = "test-calitp-ntd-report-validation"
  project                     = "cal-itp-data-infra"
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

resource "google_storage_bucket" "tfer--test-calitp-ntd-xlsx-products-clean" {
  default_event_based_hold    = "false"
  force_destroy               = "false"
  location                    = "US"
  name                        = "test-calitp-ntd-xlsx-products-clean"
  project                     = "cal-itp-data-infra"
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

resource "google_storage_bucket" "tfer--test-calitp-ntd-xlsx-products-raw" {
  default_event_based_hold    = "false"
  force_destroy               = "false"
  location                    = "US"
  name                        = "test-calitp-ntd-xlsx-products-raw"
  project                     = "cal-itp-data-infra"
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

resource "google_storage_bucket" "tfer--test-calitp-payments-littlepay-parsed" {
  default_event_based_hold    = "false"
  force_destroy               = "false"
  location                    = "US-WEST2"
  name                        = "test-calitp-payments-littlepay-parsed"
  project                     = "cal-itp-data-infra"
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

resource "google_storage_bucket" "tfer--test-calitp-payments-littlepay-raw" {
  default_event_based_hold    = "false"
  force_destroy               = "false"
  location                    = "US-WEST2"
  name                        = "test-calitp-payments-littlepay-raw"
  project                     = "cal-itp-data-infra"
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

resource "google_storage_bucket" "tfer--test-calitp-publish" {
  default_event_based_hold    = "false"
  force_destroy               = "false"
  location                    = "US-WEST2"
  name                        = "test-calitp-publish"
  project                     = "cal-itp-data-infra"
  public_access_prevention    = "inherited"
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

resource "google_storage_bucket" "tfer--test-calitp-publish-data-analysis" {
  default_event_based_hold    = "false"
  force_destroy               = "false"
  location                    = "US-WEST2"
  name                        = "test-calitp-publish-data-analysis"
  project                     = "cal-itp-data-infra"
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

resource "google_storage_bucket" "tfer--test-calitp-reports-data" {
  default_event_based_hold    = "false"
  force_destroy               = "false"
  location                    = "US-WEST2"
  name                        = "test-calitp-reports-data"
  project                     = "cal-itp-data-infra"
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

resource "google_storage_bucket" "tfer--test-calitp-sentry" {
  default_event_based_hold    = "false"
  force_destroy               = "false"
  location                    = "US-WEST2"
  name                        = "test-calitp-sentry"
  project                     = "cal-itp-data-infra"
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

resource "google_storage_bucket" "tfer--test-calitp-state-geoportal-scrape" {
  default_event_based_hold    = "false"
  force_destroy               = "false"
  location                    = "US"
  name                        = "test-calitp-state-geoportal-scrape"
  project                     = "cal-itp-data-infra"
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

resource "google_storage_bucket" "tfer--test-rt-parsed" {
  default_event_based_hold    = "false"
  force_destroy               = "false"
  location                    = "US-WEST2"
  name                        = "test-rt-parsed"
  project                     = "cal-itp-data-infra"
  public_access_prevention    = "inherited"
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

resource "google_storage_bucket" "tfer--test-rt-validations" {
  default_event_based_hold    = "false"
  force_destroy               = "false"
  location                    = "US-WEST2"
  name                        = "test-rt-validations"
  project                     = "cal-itp-data-infra"
  public_access_prevention    = "inherited"
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

resource "google_storage_bucket" "tfer--us-002E-artifacts-002E-cal-itp-data-infra-002E-appspot-002E-com" {
  default_event_based_hold    = "false"
  force_destroy               = "false"
  location                    = "US"
  name                        = "us.artifacts.cal-itp-data-infra.appspot.com"
  project                     = "cal-itp-data-infra"
  public_access_prevention    = "inherited"
  requester_pays              = "false"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = "false"
}

resource "google_storage_bucket" "tfer--us-west2-calitp-airflow2-pr-171e4e47-bucket" {
  default_event_based_hold    = "false"
  force_destroy               = "false"
  location                    = "US-WEST2"
  name                        = "us-west2-calitp-airflow2-pr-171e4e47-bucket"
  project                     = "cal-itp-data-infra"
  public_access_prevention    = "inherited"
  requester_pays              = "false"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = "false"

  lifecycle {
    ignore_changes = [labels]
  }
}

resource "google_storage_bucket" "tfer--us-west2-calitp-airflow2-pr-31e41084-bucket" {
  default_event_based_hold    = "false"
  force_destroy               = "false"
  location                    = "US-WEST2"
  name                        = "us-west2-calitp-airflow2-pr-31e41084-bucket"
  project                     = "cal-itp-data-infra"
  public_access_prevention    = "inherited"
  requester_pays              = "false"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = "false"
  lifecycle {
    ignore_changes = [labels]
  }
}

resource "google_storage_bucket" "tfer--us-west2-calitp-airflow2-pr-88ca8ec6-bucket" {
  default_event_based_hold    = "false"
  force_destroy               = "false"
  location                    = "US-WEST2"
  name                        = "us-west2-calitp-airflow2-pr-88ca8ec6-bucket"
  project                     = "cal-itp-data-infra"
  public_access_prevention    = "inherited"
  requester_pays              = "false"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = "false"
  lifecycle {
    ignore_changes = [labels]
  }
}

resource "google_storage_bucket" "calitp-gtfs" {
  location                    = "US-WEST2"
  name                        = "calitp-gtfs"
  project                     = "cal-itp-data-infra"
  uniform_bucket_level_access = "true"
  storage_class               = "STANDARD"
  force_destroy               = "true"

  website {
    main_page_suffix = "index.html"
    not_found_page   = "404.html"
  }
}

resource "google_storage_bucket" "calitp-dbt-docs" {
  default_event_based_hold    = "false"
  force_destroy               = "true"
  location                    = "US-WEST2"
  name                        = "calitp-dbt-docs"
  project                     = "cal-itp-data-infra"
  public_access_prevention    = "inherited"
  requester_pays              = "false"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"

  website {
    main_page_suffix = "index.html"
  }
}
