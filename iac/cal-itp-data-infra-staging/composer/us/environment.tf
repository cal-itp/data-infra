resource "google_composer_environment" "calitp-staging-composer" {
  name    = "calitp-staging-composer"
  region  = "us-west2"
  project = "cal-itp-data-infra-staging"

  storage_config {
    bucket = data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-staging-composer_name
  }

  config {
    software_config {
      image_version = "composer-2.8.3-airflow-2.6.3"
    }

    node_config {
      service_account = data.terraform_remote_state.iam.outputs.google_service_account_composer-service-account_id
    }
  }
}
