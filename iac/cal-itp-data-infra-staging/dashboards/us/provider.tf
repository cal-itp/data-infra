provider "google" {
  project = "cal-itp-data-infra-staging"
}

provider "metabase" {
  endpoint = "https://${data.terraform_remote_state.metabase.outputs.lb-http_metabase-staging_domain}/api"
  api_key  = data.google_secret_manager_secret_version.metabase-api-key.secret_data
}

terraform {
  required_providers {
    google = {
      version = "~> 7.10.0"
    }

    metabase = {
      source  = "flovouin/metabase"
      version = "~> 0.10.1"
    }
  }

  backend "gcs" {
    bucket = "calitp-staging-gcp-components-tfstate"
    prefix = "cal-itp-data-infra-staging/dashboards"
  }
}
