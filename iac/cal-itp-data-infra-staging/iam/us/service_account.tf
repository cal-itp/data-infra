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

resource "google_service_account" "github-actions-terraform" {
  account_id   = "github-actions-terraform"
  description  = "Service account for Github Actions to run Terraform"
  disabled     = "false"
  display_name = "Terraform"
  project      = "cal-itp-data-infra-staging"
}

resource "google_service_account" "github-actions-service-account" {
  account_id   = "github-actions-service-account"
  description  = "Service account for general Github Actions"
  disabled     = "false"
  display_name = "github_actions_services_account"
  project      = "cal-itp-data-infra-staging"
}

resource "google_service_account" "cal-bc-service-account" {
  account_id   = "cal-bc-service-account"
  description  = "Service account for Cal B/C"
  disabled     = "false"
  display_name = "cal-bc"
  project      = "cal-itp-data-infra-staging"
}

resource "google_service_account" "composer-service-account" {
  account_id   = "composer-service-account"
  description  = "Service account for Composer"
  disabled     = "false"
  display_name = "composer"
  project      = "cal-itp-data-infra-staging"
}

resource "google_service_account" "sftp-pod-service-account" {
  account_id   = "sftp-pod-service-account"
  description  = "Service account for sftp server"
  disabled     = "false"
  display_name = "sftp-pod"
  project      = "cal-itp-data-infra-staging"
}
