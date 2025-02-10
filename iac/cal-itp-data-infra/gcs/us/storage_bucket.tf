resource "google_storage_bucket" "tfer--analysis-output-models" {
  default_event_based_hold = "false"
  enable_object_retention  = "false"
  force_destroy            = "false"

  hierarchical_namespace {
    enabled = "false"
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }

    condition {
      age                                     = "0"
      created_before                          = ""
      days_since_custom_time                  = "0"
      days_since_noncurrent_time              = "0"
      num_newer_versions                      = "2"
      send_age_if_zero                        = "false"
      send_days_since_custom_time_if_zero     = "false"
      send_days_since_noncurrent_time_if_zero = "false"
      send_num_newer_versions_if_zero         = "false"
      with_state                              = "ARCHIVED"
    }
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }

    condition {
      age                                     = "0"
      created_before                          = ""
      days_since_custom_time                  = "0"
      days_since_noncurrent_time              = "7"
      num_newer_versions                      = "0"
      send_age_if_zero                        = "false"
      send_days_since_custom_time_if_zero     = "false"
      send_days_since_noncurrent_time_if_zero = "false"
      send_num_newer_versions_if_zero         = "false"
      with_state                              = "ANY"
    }
  }

  location                 = "US-WEST2"
  name                     = "analysis-output-models"
  public_access_prevention = "enforced"
  requester_pays           = "false"

  soft_delete_policy {
    retention_duration_seconds = "604800"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"

  versioning {
    enabled = "true"
  }
}

resource "google_storage_bucket" "tfer--artifacts-002E-cal-itp-data-infra-002E-appspot-002E-com" {
  default_event_based_hold = "false"
  enable_object_retention  = "false"
  force_destroy            = "false"

  hierarchical_namespace {
    enabled = "false"
  }

  location                 = "US"
  name                     = "artifacts.cal-itp-data-infra.appspot.com"
  public_access_prevention = "inherited"
  requester_pays           = "false"
  rpo                      = "DEFAULT"

  soft_delete_policy {
    retention_duration_seconds = "604800"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "false"
}

resource "google_storage_bucket" "tfer--cal-itp-data-infra-002E-appspot-002E-com" {
  default_event_based_hold = "false"
  enable_object_retention  = "false"
  force_destroy            = "false"

  hierarchical_namespace {
    enabled = "false"
  }

  location                 = "US-WEST2"
  name                     = "cal-itp-data-infra.appspot.com"
  public_access_prevention = "inherited"
  requester_pays           = "false"

  soft_delete_policy {
    retention_duration_seconds = "604800"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "false"
}

resource "google_storage_bucket" "tfer--calitp-aggregator-scraper" {
  default_event_based_hold = "false"
  enable_object_retention  = "false"
  force_destroy            = "false"

  hierarchical_namespace {
    enabled = "false"
  }

  location                 = "US-WEST2"
  name                     = "calitp-aggregator-scraper"
  public_access_prevention = "enforced"
  requester_pays           = "false"

  soft_delete_policy {
    retention_duration_seconds = "604800"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--calitp-airtable" {
  default_event_based_hold = "false"
  enable_object_retention  = "false"
  force_destroy            = "false"

  hierarchical_namespace {
    enabled = "false"
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }

    condition {
      age                                     = "0"
      created_before                          = ""
      days_since_custom_time                  = "0"
      days_since_noncurrent_time              = "0"
      num_newer_versions                      = "2"
      send_age_if_zero                        = "false"
      send_days_since_custom_time_if_zero     = "false"
      send_days_since_noncurrent_time_if_zero = "false"
      send_num_newer_versions_if_zero         = "false"
      with_state                              = "ARCHIVED"
    }
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }

    condition {
      age                                     = "0"
      created_before                          = ""
      days_since_custom_time                  = "0"
      days_since_noncurrent_time              = "7"
      num_newer_versions                      = "0"
      send_age_if_zero                        = "false"
      send_days_since_custom_time_if_zero     = "false"
      send_days_since_noncurrent_time_if_zero = "false"
      send_num_newer_versions_if_zero         = "false"
      with_state                              = "ANY"
    }
  }

  location                 = "US-WEST2"
  name                     = "calitp-airtable"
  public_access_prevention = "inherited"
  requester_pays           = "false"

  retention_policy {
    is_locked        = "false"
    retention_period = "31557600"
  }

  soft_delete_policy {
    retention_duration_seconds = "604800"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"

  versioning {
    enabled = "false"
  }
}

resource "google_storage_bucket" "tfer--calitp-amplitude-benefits-events" {
  default_event_based_hold = "false"
  enable_object_retention  = "false"
  force_destroy            = "false"

  hierarchical_namespace {
    enabled = "false"
  }

  location                 = "US-WEST2"
  name                     = "calitp-amplitude-benefits-events"
  public_access_prevention = "enforced"
  requester_pays           = "false"

  soft_delete_policy {
    retention_duration_seconds = "604800"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--calitp-analytics-data" {
  default_event_based_hold = "false"
  enable_object_retention  = "false"
  force_destroy            = "false"

  hierarchical_namespace {
    enabled = "false"
  }

  location                 = "US-WEST2"
  name                     = "calitp-analytics-data"
  public_access_prevention = "inherited"
  requester_pays           = "false"

  soft_delete_policy {
    retention_duration_seconds = "604800"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"

  versioning {
    enabled = "true"
  }
}

resource "google_storage_bucket" "tfer--calitp-backups-grafana" {
  default_event_based_hold = "false"
  enable_object_retention  = "false"
  force_destroy            = "false"

  hierarchical_namespace {
    enabled = "false"
  }

  location                 = "US-WEST2"
  name                     = "calitp-backups-grafana"
  public_access_prevention = "enforced"
  requester_pays           = "false"

  soft_delete_policy {
    retention_duration_seconds = "604800"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--calitp-backups-metabase" {
  default_event_based_hold = "false"
  enable_object_retention  = "false"
  force_destroy            = "false"

  hierarchical_namespace {
    enabled = "false"
  }

  location                 = "US-WEST1"
  name                     = "calitp-backups-metabase"
  public_access_prevention = "inherited"
  requester_pays           = "false"

  soft_delete_policy {
    retention_duration_seconds = "604800"
  }

  storage_class               = "NEARLINE"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--calitp-backups-sentry" {
  default_event_based_hold = "false"
  enable_object_retention  = "false"
  force_destroy            = "false"

  hierarchical_namespace {
    enabled = "false"
  }

  location                 = "US-WEST2"
  name                     = "calitp-backups-sentry"
  public_access_prevention = "enforced"
  requester_pays           = "false"

  soft_delete_policy {
    retention_duration_seconds = "604800"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--calitp-backups-test" {
  default_event_based_hold = "false"
  enable_object_retention  = "false"
  force_destroy            = "false"

  hierarchical_namespace {
    enabled = "false"
  }

  location                 = "US-WEST2"
  name                     = "calitp-backups-test"
  public_access_prevention = "enforced"
  requester_pays           = "false"

  soft_delete_policy {
    retention_duration_seconds = "604800"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--calitp-ci-artifacts" {
  default_event_based_hold = "false"
  enable_object_retention  = "false"
  force_destroy            = "false"

  hierarchical_namespace {
    enabled = "false"
  }

  location                 = "US-WEST2"
  name                     = "calitp-ci-artifacts"
  public_access_prevention = "enforced"
  requester_pays           = "false"

  soft_delete_policy {
    retention_duration_seconds = "604800"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--calitp-dbt-artifacts" {
  default_event_based_hold = "false"
  enable_object_retention  = "false"
  force_destroy            = "false"

  hierarchical_namespace {
    enabled = "false"
  }

  location                 = "US-WEST2"
  name                     = "calitp-dbt-artifacts"
  public_access_prevention = "enforced"
  requester_pays           = "false"

  soft_delete_policy {
    retention_duration_seconds = "604800"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--calitp-dbt-python-models" {
  default_event_based_hold = "false"
  enable_object_retention  = "false"
  force_destroy            = "false"

  hierarchical_namespace {
    enabled = "false"
  }

  location                 = "US-WEST2"
  name                     = "calitp-dbt-python-models"
  public_access_prevention = "enforced"
  requester_pays           = "false"

  soft_delete_policy {
    retention_duration_seconds = "604800"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--calitp-elavon-parsed" {
  default_event_based_hold = "false"
  enable_object_retention  = "false"
  force_destroy            = "false"

  hierarchical_namespace {
    enabled = "false"
  }

  location                 = "US-WEST2"
  name                     = "calitp-elavon-parsed"
  public_access_prevention = "enforced"
  requester_pays           = "false"

  soft_delete_policy {
    retention_duration_seconds = "604800"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--calitp-elavon-raw" {
  default_event_based_hold = "false"
  enable_object_retention  = "false"
  force_destroy            = "false"

  hierarchical_namespace {
    enabled = "false"
  }

  location                 = "US-WEST2"
  name                     = "calitp-elavon-raw"
  public_access_prevention = "enforced"
  requester_pays           = "false"

  soft_delete_policy {
    retention_duration_seconds = "604800"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--calitp-gtfs-download-config" {
  default_event_based_hold = "false"
  enable_object_retention  = "false"
  force_destroy            = "false"

  hierarchical_namespace {
    enabled = "false"
  }

  location                 = "US-WEST2"
  name                     = "calitp-gtfs-download-config"
  public_access_prevention = "inherited"
  requester_pays           = "false"

  retention_policy {
    is_locked        = "false"
    retention_period = "31557600"
  }

  soft_delete_policy {
    retention_duration_seconds = "604800"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--calitp-gtfs-rt-parsed" {
  default_event_based_hold = "false"
  enable_object_retention  = "false"
  force_destroy            = "false"

  hierarchical_namespace {
    enabled = "false"
  }

  location                 = "US-WEST2"
  name                     = "calitp-gtfs-rt-parsed"
  public_access_prevention = "inherited"
  requester_pays           = "false"

  soft_delete_policy {
    retention_duration_seconds = "604800"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--calitp-gtfs-rt-raw-deprecated" {
  default_event_based_hold = "false"
  enable_object_retention  = "false"
  force_destroy            = "false"

  hierarchical_namespace {
    enabled = "false"
  }

  location                 = "US-WEST2"
  name                     = "calitp-gtfs-rt-raw-deprecated"
  public_access_prevention = "enforced"
  requester_pays           = "false"

  soft_delete_policy {
    retention_duration_seconds = "604800"
  }

  storage_class               = "ARCHIVE"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--calitp-gtfs-rt-raw-v2" {
  default_event_based_hold = "false"
  enable_object_retention  = "false"
  force_destroy            = "false"

  hierarchical_namespace {
    enabled = "false"
  }

  location                 = "US-WEST2"
  name                     = "calitp-gtfs-rt-raw-v2"
  public_access_prevention = "inherited"
  requester_pays           = "false"

  retention_policy {
    is_locked        = "false"
    retention_period = "31557600"
  }

  soft_delete_policy {
    retention_duration_seconds = "604800"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--calitp-gtfs-rt-validation" {
  default_event_based_hold = "false"
  enable_object_retention  = "false"
  force_destroy            = "false"

  hierarchical_namespace {
    enabled = "false"
  }

  location                 = "US-WEST2"
  name                     = "calitp-gtfs-rt-validation"
  public_access_prevention = "inherited"
  requester_pays           = "false"

  soft_delete_policy {
    retention_duration_seconds = "604800"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--calitp-gtfs-schedule-parsed" {
  default_event_based_hold = "false"
  enable_object_retention  = "false"
  force_destroy            = "false"

  hierarchical_namespace {
    enabled = "false"
  }

  location                 = "US-WEST2"
  name                     = "calitp-gtfs-schedule-parsed"
  public_access_prevention = "inherited"
  requester_pays           = "false"

  soft_delete_policy {
    retention_duration_seconds = "604800"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--calitp-gtfs-schedule-parsed-hourly" {
  default_event_based_hold = "false"
  enable_object_retention  = "false"
  force_destroy            = "false"

  hierarchical_namespace {
    enabled = "false"
  }

  location                 = "US-WEST2"
  name                     = "calitp-gtfs-schedule-parsed-hourly"
  public_access_prevention = "enforced"
  requester_pays           = "false"

  soft_delete_policy {
    retention_duration_seconds = "604800"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--calitp-gtfs-schedule-raw-v2" {
  default_event_based_hold = "false"
  enable_object_retention  = "false"
  force_destroy            = "false"

  hierarchical_namespace {
    enabled = "false"
  }

  location                 = "US-WEST2"
  name                     = "calitp-gtfs-schedule-raw-v2"
  public_access_prevention = "inherited"
  requester_pays           = "false"

  retention_policy {
    is_locked        = "false"
    retention_period = "31557600"
  }

  soft_delete_policy {
    retention_duration_seconds = "604800"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--calitp-gtfs-schedule-unzipped" {
  default_event_based_hold = "false"
  enable_object_retention  = "false"
  force_destroy            = "false"

  hierarchical_namespace {
    enabled = "false"
  }

  location                 = "US-WEST2"
  name                     = "calitp-gtfs-schedule-unzipped"
  public_access_prevention = "inherited"
  requester_pays           = "false"

  soft_delete_policy {
    retention_duration_seconds = "604800"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--calitp-gtfs-schedule-unzipped-hourly" {
  default_event_based_hold = "false"
  enable_object_retention  = "false"
  force_destroy            = "false"

  hierarchical_namespace {
    enabled = "false"
  }

  location                 = "US-WEST2"
  name                     = "calitp-gtfs-schedule-unzipped-hourly"
  public_access_prevention = "enforced"
  requester_pays           = "false"

  soft_delete_policy {
    retention_duration_seconds = "604800"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--calitp-gtfs-schedule-validation" {
  default_event_based_hold = "false"
  enable_object_retention  = "false"
  force_destroy            = "false"

  hierarchical_namespace {
    enabled = "false"
  }

  location                 = "US-WEST2"
  name                     = "calitp-gtfs-schedule-validation"
  public_access_prevention = "inherited"
  requester_pays           = "false"

  soft_delete_policy {
    retention_duration_seconds = "604800"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--calitp-gtfs-schedule-validation-hourly" {
  default_event_based_hold = "false"
  enable_object_retention  = "false"
  force_destroy            = "false"

  hierarchical_namespace {
    enabled = "false"
  }

  location                 = "US-WEST2"
  name                     = "calitp-gtfs-schedule-validation-hourly"
  public_access_prevention = "enforced"
  requester_pays           = "false"

  soft_delete_policy {
    retention_duration_seconds = "604800"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--calitp-jamesl-gcp-components-tfstate" {
  default_event_based_hold = "false"
  enable_object_retention  = "false"
  force_destroy            = "false"

  hierarchical_namespace {
    enabled = "false"
  }

  location                 = "US-WEST1"
  name                     = "calitp-jamesl-gcp-components-tfstate"
  public_access_prevention = "enforced"
  requester_pays           = "false"

  soft_delete_policy {
    retention_duration_seconds = "604800"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--calitp-map-tiles" {
  cors {
    max_age_seconds = "300"
    method          = ["GET", "HEAD"]
    origin          = ["*"]
    response_header = ["etag", "range"]
  }

  default_event_based_hold = "false"
  enable_object_retention  = "false"
  force_destroy            = "false"

  hierarchical_namespace {
    enabled = "false"
  }

  location                 = "US-WEST2"
  name                     = "calitp-map-tiles"
  public_access_prevention = "inherited"
  requester_pays           = "false"

  soft_delete_policy {
    retention_duration_seconds = "604800"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--calitp-metabase-data-public" {
  default_event_based_hold = "false"
  enable_object_retention  = "false"
  force_destroy            = "false"

  hierarchical_namespace {
    enabled = "false"
  }

  location                 = "US-WEST2"
  name                     = "calitp-metabase-data-public"
  public_access_prevention = "inherited"
  requester_pays           = "false"

  soft_delete_policy {
    retention_duration_seconds = "604800"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "false"
}

resource "google_storage_bucket" "tfer--calitp-ntd-api-products" {
  default_event_based_hold = "false"
  enable_object_retention  = "false"
  force_destroy            = "false"

  hierarchical_namespace {
    enabled = "false"
  }

  location                 = "US"
  name                     = "calitp-ntd-api-products"
  public_access_prevention = "enforced"
  requester_pays           = "false"
  rpo                      = "DEFAULT"

  soft_delete_policy {
    retention_duration_seconds = "604800"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--calitp-ntd-data-products" {
  default_event_based_hold = "false"
  enable_object_retention  = "false"
  force_destroy            = "false"

  hierarchical_namespace {
    enabled = "false"
  }

  location                 = "US-WEST2"
  name                     = "calitp-ntd-data-products"
  public_access_prevention = "enforced"
  requester_pays           = "false"

  retention_policy {
    is_locked        = "false"
    retention_period = "31557600"
  }

  soft_delete_policy {
    retention_duration_seconds = "604800"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--calitp-ntd-report-validation" {
  default_event_based_hold = "false"
  enable_object_retention  = "false"
  force_destroy            = "false"

  hierarchical_namespace {
    enabled = "false"
  }

  location                 = "US-WEST2"
  name                     = "calitp-ntd-report-validation"
  public_access_prevention = "enforced"
  requester_pays           = "false"

  soft_delete_policy {
    retention_duration_seconds = "604800"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--calitp-ntd-xlsx-products-clean" {
  default_event_based_hold = "false"
  enable_object_retention  = "false"
  force_destroy            = "false"

  hierarchical_namespace {
    enabled = "false"
  }

  location                 = "US"
  name                     = "calitp-ntd-xlsx-products-clean"
  public_access_prevention = "enforced"
  requester_pays           = "false"
  rpo                      = "DEFAULT"

  soft_delete_policy {
    retention_duration_seconds = "604800"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--calitp-ntd-xlsx-products-raw" {
  default_event_based_hold = "false"
  enable_object_retention  = "false"
  force_destroy            = "false"

  hierarchical_namespace {
    enabled = "false"
  }

  location                 = "US"
  name                     = "calitp-ntd-xlsx-products-raw"
  public_access_prevention = "enforced"
  requester_pays           = "false"
  rpo                      = "DEFAULT"

  soft_delete_policy {
    retention_duration_seconds = "604800"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--calitp-payments-littlepay-parsed" {
  default_event_based_hold = "false"
  enable_object_retention  = "false"
  force_destroy            = "false"

  hierarchical_namespace {
    enabled = "false"
  }

  location                 = "US-WEST2"
  name                     = "calitp-payments-littlepay-parsed"
  public_access_prevention = "enforced"
  requester_pays           = "false"

  soft_delete_policy {
    retention_duration_seconds = "604800"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--calitp-payments-littlepay-raw" {
  default_event_based_hold = "false"
  enable_object_retention  = "false"
  force_destroy            = "false"

  hierarchical_namespace {
    enabled = "false"
  }

  location                 = "US-WEST2"
  name                     = "calitp-payments-littlepay-raw"
  public_access_prevention = "enforced"
  requester_pays           = "false"

  retention_policy {
    is_locked        = "false"
    retention_period = "31557600"
  }

  soft_delete_policy {
    retention_duration_seconds = "604800"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--calitp-prod-gcp-components-tfstate" {
  default_event_based_hold = "false"
  enable_object_retention  = "false"
  force_destroy            = "false"

  hierarchical_namespace {
    enabled = "false"
  }

  location                 = "US"
  name                     = "calitp-prod-gcp-components-tfstate"
  public_access_prevention = "inherited"
  requester_pays           = "false"
  rpo                      = "DEFAULT"

  soft_delete_policy {
    retention_duration_seconds = "604800"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--calitp-publish" {
  default_event_based_hold = "false"
  enable_object_retention  = "false"
  force_destroy            = "false"

  hierarchical_namespace {
    enabled = "false"
  }

  location                 = "US-WEST2"
  name                     = "calitp-publish"
  public_access_prevention = "inherited"
  requester_pays           = "false"

  soft_delete_policy {
    retention_duration_seconds = "604800"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--calitp-publish-data-analysis" {
  default_event_based_hold = "false"
  enable_object_retention  = "false"
  force_destroy            = "false"

  hierarchical_namespace {
    enabled = "false"
  }

  location                 = "US-WEST2"
  name                     = "calitp-publish-data-analysis"
  public_access_prevention = "inherited"
  requester_pays           = "false"

  soft_delete_policy {
    retention_duration_seconds = "604800"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--calitp-reports-data" {
  default_event_based_hold = "false"
  enable_object_retention  = "false"
  force_destroy            = "false"

  hierarchical_namespace {
    enabled = "false"
  }

  location                 = "US-WEST2"
  name                     = "calitp-reports-data"
  public_access_prevention = "enforced"
  requester_pays           = "false"

  soft_delete_policy {
    retention_duration_seconds = "604800"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--calitp-state-geoportal-scrape" {
  default_event_based_hold = "false"
  enable_object_retention  = "false"
  force_destroy            = "false"

  hierarchical_namespace {
    enabled = "false"
  }

  location                 = "US"
  name                     = "calitp-state-geoportal-scrape"
  public_access_prevention = "enforced"
  requester_pays           = "false"
  rpo                      = "DEFAULT"

  soft_delete_policy {
    retention_duration_seconds = "604800"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--calitp-state-highway-network-stops" {
  default_event_based_hold = "false"
  enable_object_retention  = "false"
  force_destroy            = "false"

  hierarchical_namespace {
    enabled = "false"
  }

  location                 = "US"
  name                     = "calitp-state-highway-network-stops"
  public_access_prevention = "enforced"
  requester_pays           = "false"
  rpo                      = "DEFAULT"

  soft_delete_policy {
    retention_duration_seconds = "604800"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--cold-storage-outputs-gtfs-data-test" {
  default_event_based_hold = "false"
  enable_object_retention  = "false"
  force_destroy            = "false"

  hierarchical_namespace {
    enabled = "false"
  }

  location                 = "US"
  name                     = "cold-storage-outputs-gtfs-data-test"
  public_access_prevention = "inherited"
  requester_pays           = "false"
  rpo                      = "DEFAULT"

  soft_delete_policy {
    retention_duration_seconds = "604800"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "false"
}

resource "google_storage_bucket" "tfer--cold-storage-outputs-gtfs-data-test-charlie-test" {
  default_event_based_hold = "false"
  enable_object_retention  = "false"
  force_destroy            = "false"

  hierarchical_namespace {
    enabled = "false"
  }

  location                 = "US"
  name                     = "cold-storage-outputs-gtfs-data-test-charlie-test"
  public_access_prevention = "inherited"
  requester_pays           = "false"
  rpo                      = "DEFAULT"

  soft_delete_policy {
    retention_duration_seconds = "604800"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "false"
}

resource "google_storage_bucket" "tfer--dataproc-staging-us-west2-1005246706141-sfgmtgyp" {
  default_event_based_hold = "false"
  enable_object_retention  = "false"
  force_destroy            = "false"

  hierarchical_namespace {
    enabled = "false"
  }

  location                 = "US-WEST2"
  name                     = "dataproc-staging-us-west2-1005246706141-sfgmtgyp"
  public_access_prevention = "inherited"
  requester_pays           = "false"

  soft_delete_policy {
    retention_duration_seconds = "0"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "false"
}

resource "google_storage_bucket" "tfer--dataproc-temp-us-west2-1005246706141-x9mtxbwg" {
  default_event_based_hold = "false"
  enable_object_retention  = "false"
  force_destroy            = "false"

  hierarchical_namespace {
    enabled = "false"
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }

    condition {
      age                                     = "90"
      created_before                          = ""
      days_since_custom_time                  = "0"
      days_since_noncurrent_time              = "0"
      num_newer_versions                      = "0"
      send_age_if_zero                        = "false"
      send_days_since_custom_time_if_zero     = "false"
      send_days_since_noncurrent_time_if_zero = "false"
      send_num_newer_versions_if_zero         = "false"
      with_state                              = "ANY"
    }
  }

  location                 = "US-WEST2"
  name                     = "dataproc-temp-us-west2-1005246706141-x9mtxbwg"
  public_access_prevention = "inherited"
  requester_pays           = "false"

  soft_delete_policy {
    retention_duration_seconds = "0"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "false"
}

resource "google_storage_bucket" "tfer--dev-calitp-aggregator-scraper" {
  default_event_based_hold = "false"
  enable_object_retention  = "false"
  force_destroy            = "false"

  hierarchical_namespace {
    enabled = "false"
  }

  location                 = "US-WEST2"
  name                     = "dev-calitp-aggregator-scraper"
  public_access_prevention = "enforced"
  requester_pays           = "false"

  soft_delete_policy {
    retention_duration_seconds = "604800"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--dev-calitp-gtfs-rt-raw" {
  default_event_based_hold = "false"
  enable_object_retention  = "false"
  force_destroy            = "false"

  hierarchical_namespace {
    enabled = "false"
  }

  location                 = "US-WEST2"
  name                     = "dev-calitp-gtfs-rt-raw"
  public_access_prevention = "inherited"
  requester_pays           = "false"

  soft_delete_policy {
    retention_duration_seconds = "604800"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--dev-calitp-test-sandbox" {
  default_event_based_hold = "false"
  enable_object_retention  = "false"
  force_destroy            = "false"

  hierarchical_namespace {
    enabled = "false"
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }

    condition {
      age                                     = "1"
      created_before                          = ""
      days_since_custom_time                  = "0"
      days_since_noncurrent_time              = "0"
      num_newer_versions                      = "0"
      send_age_if_zero                        = "false"
      send_days_since_custom_time_if_zero     = "false"
      send_days_since_noncurrent_time_if_zero = "false"
      send_num_newer_versions_if_zero         = "false"
      with_state                              = "ANY"
    }
  }

  location                 = "US-WEST2"
  name                     = "dev-calitp-test-sandbox"
  public_access_prevention = "enforced"
  requester_pays           = "false"

  soft_delete_policy {
    retention_duration_seconds = "604800"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--gtfs-data" {
  default_event_based_hold = "false"
  enable_object_retention  = "false"
  force_destroy            = "false"

  hierarchical_namespace {
    enabled = "false"
  }

  location                 = "US-WEST2"
  name                     = "gtfs-data"
  public_access_prevention = "inherited"
  requester_pays           = "false"

  soft_delete_policy {
    retention_duration_seconds = "604800"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "false"
}

resource "google_storage_bucket" "tfer--gtfs-data-reports" {
  autoclass {
    enabled                = "true"
    terminal_storage_class = "NEARLINE"
  }

  default_event_based_hold = "false"
  enable_object_retention  = "false"
  force_destroy            = "false"

  hierarchical_namespace {
    enabled = "false"
  }

  location                 = "US-WEST2"
  name                     = "gtfs-data-reports"
  public_access_prevention = "enforced"
  requester_pays           = "false"

  soft_delete_policy {
    retention_duration_seconds = "0"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--gtfs-data-test" {
  default_event_based_hold = "false"
  enable_object_retention  = "false"
  force_destroy            = "false"

  hierarchical_namespace {
    enabled = "false"
  }

  location                 = "US-WEST2"
  name                     = "gtfs-data-test"
  public_access_prevention = "inherited"
  requester_pays           = "false"

  soft_delete_policy {
    retention_duration_seconds = "604800"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--gtfs-data-test-reports" {
  autoclass {
    enabled                = "true"
    terminal_storage_class = "NEARLINE"
  }

  default_event_based_hold = "false"
  enable_object_retention  = "false"
  force_destroy            = "false"

  hierarchical_namespace {
    enabled = "false"
  }

  location                 = "US-WEST2"
  name                     = "gtfs-data-test-reports"
  public_access_prevention = "enforced"
  requester_pays           = "false"

  soft_delete_policy {
    retention_duration_seconds = "0"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--gtfs-schedule-backfill-test" {
  default_event_based_hold = "false"
  enable_object_retention  = "false"
  force_destroy            = "false"

  hierarchical_namespace {
    enabled = "false"
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }

    condition {
      age                                     = "0"
      created_before                          = ""
      days_since_custom_time                  = "0"
      days_since_noncurrent_time              = "0"
      num_newer_versions                      = "0"
      send_age_if_zero                        = "false"
      send_days_since_custom_time_if_zero     = "false"
      send_days_since_noncurrent_time_if_zero = "false"
      send_num_newer_versions_if_zero         = "false"
      with_state                              = "ANY"
    }
  }

  location                 = "US-WEST2"
  name                     = "gtfs-schedule-backfill-test"
  public_access_prevention = "enforced"
  requester_pays           = "false"

  soft_delete_policy {
    retention_duration_seconds = "604800"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--gtfs-schedule-backfill-test-deprecated" {
  default_event_based_hold = "false"
  enable_object_retention  = "false"
  force_destroy            = "false"

  hierarchical_namespace {
    enabled = "false"
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }

    condition {
      age                                     = "0"
      created_before                          = ""
      days_since_custom_time                  = "0"
      days_since_noncurrent_time              = "0"
      num_newer_versions                      = "0"
      send_age_if_zero                        = "false"
      send_days_since_custom_time_if_zero     = "false"
      send_days_since_noncurrent_time_if_zero = "false"
      send_num_newer_versions_if_zero         = "false"
      with_state                              = "ANY"
    }
  }

  location                 = "US-WEST2"
  name                     = "gtfs-schedule-backfill-test-deprecated"
  public_access_prevention = "enforced"
  requester_pays           = "false"

  soft_delete_policy {
    retention_duration_seconds = "604800"
  }

  storage_class               = "ARCHIVE"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--littlepay-data-extract-prod" {
  default_event_based_hold = "false"
  enable_object_retention  = "false"
  force_destroy            = "false"

  hierarchical_namespace {
    enabled = "false"
  }

  location                 = "US-WEST2"
  name                     = "littlepay-data-extract-prod"
  public_access_prevention = "inherited"
  requester_pays           = "false"

  soft_delete_policy {
    retention_duration_seconds = "604800"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--rt-parsed" {
  default_event_based_hold = "false"
  enable_object_retention  = "false"
  force_destroy            = "false"

  hierarchical_namespace {
    enabled = "false"
  }

  location                 = "US-WEST2"
  name                     = "rt-parsed"
  public_access_prevention = "inherited"
  requester_pays           = "false"

  soft_delete_policy {
    retention_duration_seconds = "604800"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--rt-parsed-deprecated" {
  default_event_based_hold = "false"
  enable_object_retention  = "false"
  force_destroy            = "false"

  hierarchical_namespace {
    enabled = "false"
  }

  location                 = "US-WEST2"
  name                     = "rt-parsed-deprecated"
  public_access_prevention = "enforced"
  requester_pays           = "false"

  soft_delete_policy {
    retention_duration_seconds = "604800"
  }

  storage_class               = "ARCHIVE"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--staging-002E-cal-itp-data-infra-002E-appspot-002E-com" {
  default_event_based_hold = "false"
  enable_object_retention  = "false"
  force_destroy            = "false"

  hierarchical_namespace {
    enabled = "false"
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }

    condition {
      age                                     = "15"
      created_before                          = ""
      days_since_custom_time                  = "0"
      days_since_noncurrent_time              = "0"
      num_newer_versions                      = "0"
      send_age_if_zero                        = "false"
      send_days_since_custom_time_if_zero     = "false"
      send_days_since_noncurrent_time_if_zero = "false"
      send_num_newer_versions_if_zero         = "false"
      with_state                              = "ANY"
    }
  }

  location                 = "US-WEST2"
  name                     = "staging.cal-itp-data-infra.appspot.com"
  public_access_prevention = "inherited"
  requester_pays           = "false"

  soft_delete_policy {
    retention_duration_seconds = "604800"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "false"
}

resource "google_storage_bucket" "tfer--test-calitp-aggregator-scraper" {
  default_event_based_hold = "false"
  enable_object_retention  = "false"
  force_destroy            = "false"

  hierarchical_namespace {
    enabled = "false"
  }

  location                 = "US-WEST2"
  name                     = "test-calitp-aggregator-scraper"
  public_access_prevention = "enforced"
  requester_pays           = "false"

  soft_delete_policy {
    retention_duration_seconds = "604800"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--test-calitp-airtable" {
  default_event_based_hold = "false"
  enable_object_retention  = "false"
  force_destroy            = "false"

  hierarchical_namespace {
    enabled = "false"
  }

  location                 = "US-WEST2"
  name                     = "test-calitp-airtable"
  public_access_prevention = "inherited"
  requester_pays           = "false"

  soft_delete_policy {
    retention_duration_seconds = "604800"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--test-calitp-dbt-artifacts" {
  default_event_based_hold = "false"
  enable_object_retention  = "false"
  force_destroy            = "false"

  hierarchical_namespace {
    enabled = "false"
  }

  location                 = "US-WEST2"
  name                     = "test-calitp-dbt-artifacts"
  public_access_prevention = "inherited"
  requester_pays           = "false"

  soft_delete_policy {
    retention_duration_seconds = "604800"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--test-calitp-dbt-python-models" {
  default_event_based_hold = "false"
  enable_object_retention  = "false"
  force_destroy            = "false"

  hierarchical_namespace {
    enabled = "false"
  }

  location                 = "US-WEST2"
  name                     = "test-calitp-dbt-python-models"
  public_access_prevention = "enforced"
  requester_pays           = "false"

  soft_delete_policy {
    retention_duration_seconds = "604800"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--test-calitp-elavon" {
  default_event_based_hold = "false"
  enable_object_retention  = "false"
  force_destroy            = "false"

  hierarchical_namespace {
    enabled = "false"
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }

    condition {
      age                                     = "0"
      created_before                          = ""
      days_since_custom_time                  = "0"
      days_since_noncurrent_time              = "0"
      num_newer_versions                      = "1"
      send_age_if_zero                        = "false"
      send_days_since_custom_time_if_zero     = "false"
      send_days_since_noncurrent_time_if_zero = "false"
      send_num_newer_versions_if_zero         = "false"
      with_state                              = "ARCHIVED"
    }
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }

    condition {
      age                                     = "0"
      created_before                          = ""
      days_since_custom_time                  = "0"
      days_since_noncurrent_time              = "7"
      num_newer_versions                      = "0"
      send_age_if_zero                        = "false"
      send_days_since_custom_time_if_zero     = "false"
      send_days_since_noncurrent_time_if_zero = "false"
      send_num_newer_versions_if_zero         = "false"
      with_state                              = "ANY"
    }
  }

  location                 = "US-WEST2"
  name                     = "test-calitp-elavon"
  public_access_prevention = "enforced"
  requester_pays           = "false"

  soft_delete_policy {
    retention_duration_seconds = "604800"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"

  versioning {
    enabled = "true"
  }
}

resource "google_storage_bucket" "tfer--test-calitp-elavon-parsed" {
  default_event_based_hold = "false"
  enable_object_retention  = "false"
  force_destroy            = "false"

  hierarchical_namespace {
    enabled = "false"
  }

  location                 = "US-WEST2"
  name                     = "test-calitp-elavon-parsed"
  public_access_prevention = "enforced"
  requester_pays           = "false"

  soft_delete_policy {
    retention_duration_seconds = "604800"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--test-calitp-elavon-raw" {
  default_event_based_hold = "false"
  enable_object_retention  = "false"
  force_destroy            = "false"

  hierarchical_namespace {
    enabled = "false"
  }

  location                 = "US-WEST2"
  name                     = "test-calitp-elavon-raw"
  public_access_prevention = "enforced"
  requester_pays           = "false"

  soft_delete_policy {
    retention_duration_seconds = "604800"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--test-calitp-gtfs-config" {
  default_event_based_hold = "false"
  enable_object_retention  = "false"
  force_destroy            = "false"

  hierarchical_namespace {
    enabled = "false"
  }

  location                 = "US-WEST2"
  name                     = "test-calitp-gtfs-config"
  public_access_prevention = "inherited"
  requester_pays           = "false"

  soft_delete_policy {
    retention_duration_seconds = "604800"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--test-calitp-gtfs-download-config" {
  default_event_based_hold = "false"
  enable_object_retention  = "false"
  force_destroy            = "false"

  hierarchical_namespace {
    enabled = "false"
  }

  location                 = "US-WEST2"
  name                     = "test-calitp-gtfs-download-config"
  public_access_prevention = "inherited"
  requester_pays           = "false"

  soft_delete_policy {
    retention_duration_seconds = "604800"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--test-calitp-gtfs-raw" {
  default_event_based_hold = "false"
  enable_object_retention  = "false"
  force_destroy            = "false"

  hierarchical_namespace {
    enabled = "false"
  }

  location                 = "US-WEST2"
  name                     = "test-calitp-gtfs-raw"
  public_access_prevention = "inherited"
  requester_pays           = "false"

  soft_delete_policy {
    retention_duration_seconds = "604800"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--test-calitp-gtfs-rt-parsed" {
  default_event_based_hold = "false"
  enable_object_retention  = "false"
  force_destroy            = "false"

  hierarchical_namespace {
    enabled = "false"
  }

  location                 = "US-WEST2"
  name                     = "test-calitp-gtfs-rt-parsed"
  public_access_prevention = "inherited"
  requester_pays           = "false"

  soft_delete_policy {
    retention_duration_seconds = "604800"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--test-calitp-gtfs-rt-raw" {
  default_event_based_hold = "false"
  enable_object_retention  = "false"
  force_destroy            = "false"

  hierarchical_namespace {
    enabled = "false"
  }

  location                 = "US-WEST2"
  name                     = "test-calitp-gtfs-rt-raw"
  public_access_prevention = "inherited"
  requester_pays           = "false"

  soft_delete_policy {
    retention_duration_seconds = "604800"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--test-calitp-gtfs-rt-raw-v2" {
  default_event_based_hold = "false"
  enable_object_retention  = "false"
  force_destroy            = "false"

  hierarchical_namespace {
    enabled = "false"
  }

  location                 = "US-WEST2"
  name                     = "test-calitp-gtfs-rt-raw-v2"
  public_access_prevention = "inherited"
  requester_pays           = "false"

  soft_delete_policy {
    retention_duration_seconds = "604800"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--test-calitp-gtfs-rt-validation" {
  default_event_based_hold = "false"
  enable_object_retention  = "false"
  force_destroy            = "false"

  hierarchical_namespace {
    enabled = "false"
  }

  location                 = "US-WEST2"
  name                     = "test-calitp-gtfs-rt-validation"
  public_access_prevention = "inherited"
  requester_pays           = "false"

  soft_delete_policy {
    retention_duration_seconds = "604800"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--test-calitp-gtfs-schedule-parsed" {
  default_event_based_hold = "false"
  enable_object_retention  = "false"
  force_destroy            = "false"

  hierarchical_namespace {
    enabled = "false"
  }

  location                 = "US-WEST2"
  name                     = "test-calitp-gtfs-schedule-parsed"
  public_access_prevention = "inherited"
  requester_pays           = "false"

  soft_delete_policy {
    retention_duration_seconds = "604800"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--test-calitp-gtfs-schedule-parsed-hourly" {
  default_event_based_hold = "false"
  enable_object_retention  = "false"
  force_destroy            = "false"

  hierarchical_namespace {
    enabled = "false"
  }

  location                 = "US-WEST2"
  name                     = "test-calitp-gtfs-schedule-parsed-hourly"
  public_access_prevention = "enforced"
  requester_pays           = "false"

  soft_delete_policy {
    retention_duration_seconds = "604800"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--test-calitp-gtfs-schedule-processed" {
  default_event_based_hold = "false"
  enable_object_retention  = "false"
  force_destroy            = "false"

  hierarchical_namespace {
    enabled = "false"
  }

  location                 = "US-WEST2"
  name                     = "test-calitp-gtfs-schedule-processed"
  public_access_prevention = "inherited"
  requester_pays           = "false"

  soft_delete_policy {
    retention_duration_seconds = "604800"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--test-calitp-gtfs-schedule-raw" {
  default_event_based_hold = "false"
  enable_object_retention  = "false"
  force_destroy            = "false"

  hierarchical_namespace {
    enabled = "false"
  }

  location                 = "US-WEST2"
  name                     = "test-calitp-gtfs-schedule-raw"
  public_access_prevention = "inherited"
  requester_pays           = "false"

  retention_policy {
    is_locked        = "false"
    retention_period = "2678400"
  }

  soft_delete_policy {
    retention_duration_seconds = "604800"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--test-calitp-gtfs-schedule-raw-v2" {
  default_event_based_hold = "false"
  enable_object_retention  = "false"
  force_destroy            = "false"

  hierarchical_namespace {
    enabled = "false"
  }

  location                 = "US-WEST2"
  name                     = "test-calitp-gtfs-schedule-raw-v2"
  public_access_prevention = "inherited"
  requester_pays           = "false"

  soft_delete_policy {
    retention_duration_seconds = "604800"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--test-calitp-gtfs-schedule-raw-v2-backfill-test" {
  default_event_based_hold = "false"
  enable_object_retention  = "false"
  force_destroy            = "false"

  hierarchical_namespace {
    enabled = "false"
  }

  location                 = "US-WEST2"
  name                     = "test-calitp-gtfs-schedule-raw-v2-backfill-test"
  public_access_prevention = "enforced"
  requester_pays           = "false"

  soft_delete_policy {
    retention_duration_seconds = "604800"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--test-calitp-gtfs-schedule-unzipped" {
  default_event_based_hold = "false"
  enable_object_retention  = "false"
  force_destroy            = "false"

  hierarchical_namespace {
    enabled = "false"
  }

  location                 = "US-WEST2"
  name                     = "test-calitp-gtfs-schedule-unzipped"
  public_access_prevention = "enforced"
  requester_pays           = "false"

  soft_delete_policy {
    retention_duration_seconds = "604800"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--test-calitp-gtfs-schedule-unzipped-hourly" {
  default_event_based_hold = "false"
  enable_object_retention  = "false"
  force_destroy            = "false"

  hierarchical_namespace {
    enabled = "false"
  }

  location                 = "US-WEST2"
  name                     = "test-calitp-gtfs-schedule-unzipped-hourly"
  public_access_prevention = "enforced"
  requester_pays           = "false"

  soft_delete_policy {
    retention_duration_seconds = "604800"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--test-calitp-gtfs-schedule-validation" {
  default_event_based_hold = "false"
  enable_object_retention  = "false"
  force_destroy            = "false"

  hierarchical_namespace {
    enabled = "false"
  }

  location                 = "US-WEST2"
  name                     = "test-calitp-gtfs-schedule-validation"
  public_access_prevention = "inherited"
  requester_pays           = "false"

  soft_delete_policy {
    retention_duration_seconds = "604800"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--test-calitp-gtfs-schedule-validation-hourly" {
  default_event_based_hold = "false"
  enable_object_retention  = "false"
  force_destroy            = "false"

  hierarchical_namespace {
    enabled = "false"
  }

  location                 = "US-WEST2"
  name                     = "test-calitp-gtfs-schedule-validation-hourly"
  public_access_prevention = "enforced"
  requester_pays           = "false"

  soft_delete_policy {
    retention_duration_seconds = "604800"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--test-calitp-ntd-api-products" {
  default_event_based_hold = "false"
  enable_object_retention  = "false"
  force_destroy            = "false"

  hierarchical_namespace {
    enabled = "false"
  }

  location                 = "US"
  name                     = "test-calitp-ntd-api-products"
  public_access_prevention = "enforced"
  requester_pays           = "false"
  rpo                      = "DEFAULT"

  soft_delete_policy {
    retention_duration_seconds = "604800"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--test-calitp-ntd-data-products" {
  default_event_based_hold = "false"
  enable_object_retention  = "false"
  force_destroy            = "false"

  hierarchical_namespace {
    enabled = "false"
  }

  location                 = "US-WEST2"
  name                     = "test-calitp-ntd-data-products"
  public_access_prevention = "enforced"
  requester_pays           = "false"

  soft_delete_policy {
    retention_duration_seconds = "604800"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--test-calitp-ntd-report-validation" {
  default_event_based_hold = "false"
  enable_object_retention  = "false"
  force_destroy            = "false"

  hierarchical_namespace {
    enabled = "false"
  }

  location                 = "US-WEST2"
  name                     = "test-calitp-ntd-report-validation"
  public_access_prevention = "enforced"
  requester_pays           = "false"

  soft_delete_policy {
    retention_duration_seconds = "604800"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--test-calitp-ntd-xlsx-products-clean" {
  default_event_based_hold = "false"
  enable_object_retention  = "false"
  force_destroy            = "false"

  hierarchical_namespace {
    enabled = "false"
  }

  location                 = "US"
  name                     = "test-calitp-ntd-xlsx-products-clean"
  public_access_prevention = "enforced"
  requester_pays           = "false"
  rpo                      = "DEFAULT"

  soft_delete_policy {
    retention_duration_seconds = "604800"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--test-calitp-ntd-xlsx-products-raw" {
  default_event_based_hold = "false"
  enable_object_retention  = "false"
  force_destroy            = "false"

  hierarchical_namespace {
    enabled = "false"
  }

  location                 = "US"
  name                     = "test-calitp-ntd-xlsx-products-raw"
  public_access_prevention = "enforced"
  requester_pays           = "false"
  rpo                      = "DEFAULT"

  soft_delete_policy {
    retention_duration_seconds = "604800"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--test-calitp-payments-littlepay-parsed" {
  default_event_based_hold = "false"
  enable_object_retention  = "false"
  force_destroy            = "false"

  hierarchical_namespace {
    enabled = "false"
  }

  location                 = "US-WEST2"
  name                     = "test-calitp-payments-littlepay-parsed"
  public_access_prevention = "enforced"
  requester_pays           = "false"

  soft_delete_policy {
    retention_duration_seconds = "604800"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--test-calitp-payments-littlepay-raw" {
  default_event_based_hold = "false"
  enable_object_retention  = "false"
  force_destroy            = "false"

  hierarchical_namespace {
    enabled = "false"
  }

  location                 = "US-WEST2"
  name                     = "test-calitp-payments-littlepay-raw"
  public_access_prevention = "enforced"
  requester_pays           = "false"

  soft_delete_policy {
    retention_duration_seconds = "604800"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--test-calitp-publish" {
  default_event_based_hold = "false"
  enable_object_retention  = "false"
  force_destroy            = "false"

  hierarchical_namespace {
    enabled = "false"
  }

  location                 = "US-WEST2"
  name                     = "test-calitp-publish"
  public_access_prevention = "inherited"
  requester_pays           = "false"

  soft_delete_policy {
    retention_duration_seconds = "604800"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--test-calitp-publish-data-analysis" {
  default_event_based_hold = "false"
  enable_object_retention  = "false"
  force_destroy            = "false"

  hierarchical_namespace {
    enabled = "false"
  }

  location                 = "US-WEST2"
  name                     = "test-calitp-publish-data-analysis"
  public_access_prevention = "enforced"
  requester_pays           = "false"

  soft_delete_policy {
    retention_duration_seconds = "604800"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--test-calitp-reports-data" {
  default_event_based_hold = "false"
  enable_object_retention  = "false"
  force_destroy            = "false"

  hierarchical_namespace {
    enabled = "false"
  }

  location                 = "US-WEST2"
  name                     = "test-calitp-reports-data"
  public_access_prevention = "enforced"
  requester_pays           = "false"

  soft_delete_policy {
    retention_duration_seconds = "604800"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--test-calitp-sentry" {
  default_event_based_hold = "false"
  enable_object_retention  = "false"
  force_destroy            = "false"

  hierarchical_namespace {
    enabled = "false"
  }

  location                 = "US-WEST2"
  name                     = "test-calitp-sentry"
  public_access_prevention = "enforced"
  requester_pays           = "false"

  soft_delete_policy {
    retention_duration_seconds = "604800"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--test-calitp-state-geoportal-scrape" {
  default_event_based_hold = "false"
  enable_object_retention  = "false"
  force_destroy            = "false"

  hierarchical_namespace {
    enabled = "false"
  }

  location                 = "US"
  name                     = "test-calitp-state-geoportal-scrape"
  public_access_prevention = "enforced"
  requester_pays           = "false"
  rpo                      = "DEFAULT"

  soft_delete_policy {
    retention_duration_seconds = "604800"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--test-rt-parsed" {
  default_event_based_hold = "false"
  enable_object_retention  = "false"
  force_destroy            = "false"

  hierarchical_namespace {
    enabled = "false"
  }

  location                 = "US-WEST2"
  name                     = "test-rt-parsed"
  public_access_prevention = "inherited"
  requester_pays           = "false"

  soft_delete_policy {
    retention_duration_seconds = "604800"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--test-rt-validations" {
  default_event_based_hold = "false"
  enable_object_retention  = "false"
  force_destroy            = "false"

  hierarchical_namespace {
    enabled = "false"
  }

  location                 = "US-WEST2"
  name                     = "test-rt-validations"
  public_access_prevention = "inherited"
  requester_pays           = "false"

  soft_delete_policy {
    retention_duration_seconds = "604800"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "tfer--us-002E-artifacts-002E-cal-itp-data-infra-002E-appspot-002E-com" {
  default_event_based_hold = "false"
  enable_object_retention  = "false"
  force_destroy            = "false"

  hierarchical_namespace {
    enabled = "false"
  }

  location                 = "US"
  name                     = "us.artifacts.cal-itp-data-infra.appspot.com"
  public_access_prevention = "inherited"
  requester_pays           = "false"
  rpo                      = "DEFAULT"

  soft_delete_policy {
    retention_duration_seconds = "604800"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "false"
}

resource "google_storage_bucket" "tfer--us-west2-calitp-airflow2-pr-171e4e47-bucket" {
  default_event_based_hold = "false"
  enable_object_retention  = "false"
  force_destroy            = "false"

  hierarchical_namespace {
    enabled = "false"
  }

  location                 = "US-WEST2"
  name                     = "us-west2-calitp-airflow2-pr-171e4e47-bucket"
  public_access_prevention = "inherited"
  requester_pays           = "false"

  soft_delete_policy {
    retention_duration_seconds = "604800"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "false"
}

resource "google_storage_bucket" "tfer--us-west2-calitp-airflow2-pr-31e41084-bucket" {
  default_event_based_hold = "false"
  enable_object_retention  = "false"
  force_destroy            = "false"

  hierarchical_namespace {
    enabled = "false"
  }

  location                 = "US-WEST2"
  name                     = "us-west2-calitp-airflow2-pr-31e41084-bucket"
  public_access_prevention = "inherited"
  requester_pays           = "false"

  soft_delete_policy {
    retention_duration_seconds = "604800"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "false"
}

resource "google_storage_bucket" "tfer--us-west2-calitp-airflow2-pr-88ca8ec6-bucket" {
  default_event_based_hold = "false"
  enable_object_retention  = "false"
  force_destroy            = "false"

  hierarchical_namespace {
    enabled = "false"
  }

  location                 = "US-WEST2"
  name                     = "us-west2-calitp-airflow2-pr-88ca8ec6-bucket"
  public_access_prevention = "inherited"
  requester_pays           = "false"

  soft_delete_policy {
    retention_duration_seconds = "604800"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "false"
}
