resource "google_composer_environment" "calitp-staging-composer" {
  name    = "calitp-staging-composer"
  region  = "us-west2"
  project = "cal-itp-data-infra-staging"

  storage_config {
    bucket = data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-staging-composer_name
  }

  config {
    node_config {
      service_account = data.terraform_remote_state.iam.outputs.google_service_account_composer-service-account_id
    }

    software_config {
      image_version = "composer-2.8.3-airflow-2.6.3"

      airflow_config_overrides = {
        core-dags_are_paused_at_creation = "True"
        core-dagbag_import_timeout = 500
      }

      pypi_packages = local.pypi_packages

      env_variables = local.env_variables
    }
  }
}
