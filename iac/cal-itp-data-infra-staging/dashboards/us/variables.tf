data "terraform_remote_state" "metabase" {
  backend = "gcs"

  config = {
    bucket = "calitp-staging-gcp-components-tfstate"
    prefix = "cal-itp-data-infra-staging/metabase"
  }
}

data "terraform_remote_state" "iam" {
  backend = "gcs"

  config = {
    bucket = "calitp-staging-gcp-components-tfstate"
    prefix = "cal-itp-data-infra-staging/iam"
  }
}

data "google_secret_manager_secret_version" "metabase-api-key" {
  secret     = "metabase-api-key"
  depends_on = [google_secret_manager_secret_version.metabase-api-key]
}
