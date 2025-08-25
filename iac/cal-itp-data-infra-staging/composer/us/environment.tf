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
        memory_gb  = 1
        storage_gb = 1
        count      = 1
      }
      web_server {
        cpu        = 1
        memory_gb  = 2
        storage_gb = 1
      }
      worker {
        cpu        = 2
        memory_gb  = 4
        storage_gb = 1
        min_count  = 1
        max_count  = 2
      }
    }

    environment_size = "ENVIRONMENT_SIZE_SMALL"

    software_config {
      image_version = "composer-2.8.6-airflow-2.7.3"

      airflow_config_overrides = {
        celery-worker_concurrency                  = 2
        core-dag_file_processor_timeout            = 1200
        core-dagbag_import_timeout                 = 600
        core-dags_are_paused_at_creation           = "True"
        email-email_backend                        = "airflow.utils.email.send_email_smtp"
        email-from_email                           = "bot@calitp.org"
        email-email_conn_id                        = "smtp_postmark"
        scheduler-min_file_process_interval        = 120
        scheduler-scheduler_health_check_threshold = 120
        secrets-backend                            = "airflow.providers.google.cloud.secrets.secret_manager.CloudSecretManagerBackend"
        smtp-smtp_starttls                         = true
        smtp-smtp_mail_from                        = "bot@calitp.org"
        webserver-reload_on_plugin_change          = "True"
      }

      pypi_packages = local.pypi_packages

      env_variables = merge(local.env_variables, {
        "POD_LOCATION"                                         = "us-west2",
        "POD_CLUSTER_NAME"                                     = data.terraform_remote_state.gke.outputs.google_container_cluster_airflow-jobs-staging_name,
        "POD_SECRETS_NAMESPACE"                                = local.namespace,
        "SERVICE_ACCOUNT_NAME"                                 = local.service_account_name,
        "CALITP_BUCKET__AGGREGATOR_SCRAPER"                    = "gs://${data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-staging-aggregator-scraper_name}",
        "CALITP_BUCKET__AIRTABLE"                              = "gs://${data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-staging-airtable_name}",
        "CALITP_BUCKET__AMPLITUDE_BENEFITS_EVENTS"             = "gs://${data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-staging-amplitude-benefits-events_name}",
        "CALITP_BUCKET__ANALYSIS_OUTPUT_MODELS"                = "gs://${data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-staging-analysis-output-models_name}",
        "CALITP_BUCKET__DBT_ARTIFACTS"                         = "gs://${data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-staging-dbt-artifacts_name}",
        "CALITP_BUCKET__DBT_DOCS"                              = "gs://${data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-staging-dbt-docs_name}",
        "CALITP_BUCKET__ELAVON_PARSED"                         = "gs://${data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-staging-elavon-parsed_name}",
        "CALITP_BUCKET__ELAVON_RAW"                            = "gs://${data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-staging-elavon-raw_name}",
        "CALITP_BUCKET__GTFS_DOWNLOAD_CONFIG"                  = "gs://${data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-staging-gtfs-download-config_name}",
        "CALITP_BUCKET__GTFS_DOWNLOAD_CONFIG_PROD_SOURCE"      = "gs://${data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-staging-gtfs-download-config_name}",
        "CALITP_BUCKET__GTFS_DOWNLOAD_CONFIG_TEST_DESTINATION" = "gs://${data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-staging-gtfs-download-config-test_name}",
        "CALITP_BUCKET__GTFS_RT_PARSED"                        = "gs://${data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-staging-gtfs-rt-parsed_name}",
        "CALITP_BUCKET__GTFS_RT_RAW"                           = "gs://${data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-staging-gtfs-rt-raw-v2_name}",
        "CALITP_BUCKET__GTFS_RT_VALIDATION"                    = "gs://${data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-staging-gtfs-rt-validation_name}",
        "CALITP_BUCKET__GTFS_SCHEDULE_PARSED"                  = "gs://${data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-staging-gtfs-schedule-parsed_name}",
        "CALITP_BUCKET__GTFS_SCHEDULE_PARSED_HOURLY"           = "gs://${data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-staging-gtfs-schedule-parsed-hourly_name}",
        "CALITP_BUCKET__GTFS_SCHEDULE_RAW"                     = "gs://${data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-staging-gtfs-schedule-raw-v2_name}",
        "CALITP_BUCKET__GTFS_SCHEDULE_UNZIPPED"                = "gs://${data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-staging-gtfs-schedule-unzipped_name}",
        "CALITP_BUCKET__GTFS_SCHEDULE_UNZIPPED_HOURLY"         = "gs://${data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-staging-gtfs-schedule-unzipped-hourly_name}",
        "CALITP_BUCKET__GTFS_SCHEDULE_VALIDATION"              = "gs://${data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-staging-gtfs-schedule-validation_name}",
        "CALITP_BUCKET__GTFS_SCHEDULE_VALIDATION_HOURLY"       = "gs://${data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-staging-gtfs-schedule-validation-hourly_name}",
        "CALITP_BUCKET__KUBA"                                  = "gs://${data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-staging-kuba_name}",
        "CALITP_BUCKET__LITTLEPAY_PARSED"                      = "gs://${data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-staging-payments-littlepay-parsed_name}",
        "CALITP_BUCKET__LITTLEPAY_PARSED_V3"                   = "gs://${data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-staging-payments-littlepay-parsed-v3_name}",
        "CALITP_BUCKET__LITTLEPAY_RAW"                         = "gs://${data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-staging-payments-littlepay-raw_name}",
        "CALITP_BUCKET__LITTLEPAY_RAW_V3"                      = "gs://${data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-staging-payments-littlepay-raw-v3_name}",
        "CALITP_BUCKET__NTD_API_DATA_PRODUCTS"                 = "gs://${data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-staging-ntd-api-products_name}",
        "CALITP_BUCKET__NTD_REPORT_VALIDATION"                 = "gs://${data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-staging-ntd-report-validation_name}",
        "CALITP_BUCKET__NTD_XLSX_DATA_PRODUCTS__CLEAN"         = "gs://${data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-staging-ntd-xlsx-products-clean_name}",
        "CALITP_BUCKET__NTD_XLSX_DATA_PRODUCTS__RAW"           = "gs://${data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-staging-ntd-xlsx-products-raw_name}",
        "CALITP_BUCKET__PUBLISH"                               = "gs://${data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-staging-publish_name}",
        "CALITP_BUCKET__SENTRY_EVENTS"                         = "gs://${data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-staging-sentry_name}",
        "CALITP_BUCKET__STATE_GEOPORTAL_DATA_PRODUCTS"         = "gs://${data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-staging-state-geoportal-scrape_name}",
      })
    }
  }
}
