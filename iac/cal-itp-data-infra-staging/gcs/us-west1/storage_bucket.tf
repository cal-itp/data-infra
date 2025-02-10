resource "google_storage_bucket" "tfer--calitp-staging-data-analyses-portfolio" {
  default_event_based_hold = "false"
  enable_object_retention  = "false"
  force_destroy            = "false"

  hierarchical_namespace {
    enabled = "false"
  }

  location                 = "US-WEST2"
  name                     = "calitp-staging-data-analyses-portfolio"
  public_access_prevention = "inherited"
  requester_pays           = "false"

  soft_delete_policy {
    retention_duration_seconds = "604800"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "false"
}

resource "google_storage_bucket" "tfer--calitp-staging-data-analyses-portfolio-draft" {
  default_event_based_hold = "false"
  enable_object_retention  = "false"
  force_destroy            = "false"

  hierarchical_namespace {
    enabled = "false"
  }

  location                 = "US-WEST2"
  name                     = "calitp-staging-data-analyses-portfolio-draft"
  public_access_prevention = "inherited"
  requester_pays           = "false"

  soft_delete_policy {
    retention_duration_seconds = "604800"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "false"

  website {
    main_page_suffix = "index.html"
  }
}

resource "google_storage_bucket" "tfer--dataproc-staging-us-west2-473674835135-t87wkokr" {
  default_event_based_hold = "false"
  enable_object_retention  = "false"
  force_destroy            = "false"

  hierarchical_namespace {
    enabled = "false"
  }

  location                 = "US-WEST2"
  name                     = "dataproc-staging-us-west2-473674835135-t87wkokr"
  public_access_prevention = "inherited"
  requester_pays           = "false"

  soft_delete_policy {
    retention_duration_seconds = "0"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "false"
}

resource "google_storage_bucket" "tfer--dataproc-temp-us-west2-473674835135-yuzmmdyk" {
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
  name                     = "dataproc-temp-us-west2-473674835135-yuzmmdyk"
  public_access_prevention = "inherited"
  requester_pays           = "false"

  soft_delete_policy {
    retention_duration_seconds = "0"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "false"
}

resource "google_storage_bucket" "tfer--test-calitp-amplitude-benefits-events" {
  default_event_based_hold = "false"
  enable_object_retention  = "false"
  force_destroy            = "false"

  hierarchical_namespace {
    enabled = "false"
  }

  location                 = "US-WEST2"
  name                     = "test-calitp-amplitude-benefits-events"
  public_access_prevention = "enforced"
  requester_pays           = "false"

  soft_delete_policy {
    retention_duration_seconds = "604800"
  }

  storage_class               = "STANDARD"
  uniform_bucket_level_access = "true"
}
