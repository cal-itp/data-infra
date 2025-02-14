resource "google_service_account" "tfer--101455296324690994963" {
  account_id   = "gh-actions-publisher"
  description  = "Service account for GH Actions to publish to GCS"
  disabled     = "false"
  display_name = "GH Actions Publisher"
  project      = "cal-itp-data-infra-staging"
}

resource "google_service_account" "tfer--111242760977002129583" {
  account_id   = "amplitude"
  disabled     = "true"
  display_name = "Amplitude"
  project      = "cal-itp-data-infra-staging"
}

resource "google_service_account" "tfer--111824761856041678305" {
  account_id = "local-airflow-dev"
  disabled   = "false"
  project    = "cal-itp-data-infra-staging"
}

resource "google_service_account" "tfer--111881979116192190399" {
  account_id   = "metabase"
  disabled     = "false"
  display_name = "metabase"
  project      = "cal-itp-data-infra-staging"
}
