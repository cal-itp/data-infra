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

resource "google_storage_bucket" "calitp-staging-cal-bc" {
  default_event_based_hold    = "false"
  force_destroy               = "true"
  location                    = "US-WEST2"
  name                        = "calitp-staging-cal-bc"
  project                     = "cal-itp-data-infra-staging"
  public_access_prevention    = "inherited"
  requester_pays              = "false"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"

  lifecycle {
    ignore_changes = [labels]
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

resource "google_storage_bucket" "calitp-staging-pytest" {
  name                        = "calitp-staging-pytest"
  default_event_based_hold    = "false"
  force_destroy               = "true"
  location                    = "US-WEST2"
  project                     = "cal-itp-data-infra-staging"
  public_access_prevention    = "inherited"
  requester_pays              = "false"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "calitp-staging-enghouse-raw" {
  default_event_based_hold    = "false"
  force_destroy               = "true"
  location                    = "US-WEST2"
  name                        = "calitp-staging-enghouse-raw"
  project                     = "cal-itp-data-infra-staging"
  public_access_prevention    = "inherited"
  requester_pays              = "false"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

# TODO: Delete once is totally replaced by calitp-staging-enghouse-raw
resource "google_storage_bucket" "cal-itp-data-infra-enghouse-raw" {
  default_event_based_hold    = "false"
  force_destroy               = "true"
  location                    = "US-WEST2"
  name                        = "cal-itp-data-infra-staging-enghouse-raw"
  project                     = "cal-itp-data-infra-staging"
  public_access_prevention    = "inherited"
  requester_pays              = "false"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}

resource "google_storage_bucket" "calitp-staging" {
  for_each                    = local.environment_buckets
  name                        = each.key
  default_event_based_hold    = "false"
  force_destroy               = "true"
  location                    = "US-WEST2"
  project                     = "cal-itp-data-infra-staging"
  public_access_prevention    = "inherited"
  requester_pays              = "false"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"

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
}

resource "google_storage_bucket" "calitp-reports-staging" {
  default_event_based_hold    = "false"
  force_destroy               = "true"
  location                    = "US-WEST2"
  name                        = "calitp-reports-staging"
  project                     = "cal-itp-data-infra-staging"
  public_access_prevention    = "inherited"
  requester_pays              = "false"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"

  website {
    main_page_suffix = "index.html"
  }
}

resource "google_storage_bucket" "calitp-reports-data-staging" {
  default_event_based_hold    = "false"
  force_destroy               = "false"
  location                    = "US-WEST2"
  name                        = "calitp-reports-data-staging"
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

resource "google_storage_bucket" "calitp-analysis-staging" {
  default_event_based_hold    = "false"
  force_destroy               = "true"
  location                    = "US-WEST2"
  name                        = "calitp-analysis-staging"
  project                     = "cal-itp-data-infra-staging"
  public_access_prevention    = "inherited"
  requester_pays              = "false"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"

  website {
    main_page_suffix = "index.html"
  }
}
