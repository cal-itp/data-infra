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

    workloads_config {
      scheduler {
        cpu        = 1
        memory_gb  = 2
        storage_gb = 1
        count      = 1
      }
      web_server {
        cpu        = 0.5
        memory_gb  = 2
        storage_gb = 1
      }
      worker {
        cpu        = 1
        memory_gb  = 2
        storage_gb = 1
        min_count  = 1
        max_count  = 1
      }
    }

    environment_size = "ENVIRONMENT_SIZE_SMALL"

    software_config {
      image_version = "composer-2.8.3-airflow-2.6.3"

      airflow_config_overrides = {
        core-dags_are_paused_at_creation    = "True"
        core-dagbag_import_timeout          = 600
        core-dag_file_processor_timeout     = 1200
        scheduler-min_file_process_interval = 120
        webserver-reload_on_plugin_change   = "False"
      }

      pypi_packages = local.pypi_packages

      env_variables = merge(local.env_variables, {
        "POD_LOCATION"     = "us-west2",
        "POD_CLUSTER_NAME" = data.terraform_remote_state.gke.outputs.google_container_cluster_airflow-jobs-staging_name
      })
    }
  }
}
