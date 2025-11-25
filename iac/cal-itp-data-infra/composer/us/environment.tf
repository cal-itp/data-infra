resource "google_composer_environment" "calitp-composer" {
  name    = "calitp-composer"
  region  = "us-west2"
  project = "cal-itp-data-infra"

  storage_config {
    bucket = data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-composer_name
  }

  config {
    node_config {
      service_account = data.terraform_remote_state.iam.outputs.google_service_account_composer-service-account_id
    }

    workloads_config {
      scheduler {
        cpu        = 2
        memory_gb  = 2
        storage_gb = 1
        count      = 1
      }
      web_server {
        cpu        = 1
        memory_gb  = 2
        storage_gb = 1
      }
      worker {
        cpu        = 4
        memory_gb  = 13
        storage_gb = 5
        min_count  = 1
        max_count  = 8
      }
    }

    environment_size = "ENVIRONMENT_SIZE_MEDIUM"

    software_config {
      image_version = "composer-2.10.2-airflow-2.9.3"

      airflow_config_overrides = {
        celery-worker_concurrency                  = 4
        core-dag_file_processor_timeout            = 1200
        core-dagbag_import_timeout                 = 600
        core-dags_are_paused_at_creation           = true
        email-email_backend                        = "airflow.utils.email.send_email_smtp"
        email-email_conn_id                        = "smtp_postmark"
        email-from_email                           = "airflow-bot@calitp.org"
        scheduler-min_file_process_interval        = 120
        scheduler-scheduler_health_check_threshold = 120
        secrets-backend                            = "airflow.providers.google.cloud.secrets.secret_manager.CloudSecretManagerBackend"
        smtp-smtp_mail_from                        = "airflow-bot@calitp.org"
        smtp-smtp_starttls                         = true
        smtp-smtp_host                             = "smtp.postmarkapp.com"
        smtp-smtp_port                             = 587
        webserver-reload_on_plugin_change          = true
        webserver-show_trigger_form_if_no_params   = true
      }

      pypi_packages = local.pypi_packages

      env_variables = merge(local.env_variables, {
        "POD_LOCATION"                                         = "us-west2",
        "POD_CLUSTER_NAME"                                     = data.terraform_remote_state.gke.outputs.google_container_cluster_airflow-jobs_name,
        "POD_SECRETS_NAMESPACE"                                = local.namespace,
        "SERVICE_ACCOUNT_NAME"                                 = local.service_account_name,
        "CALITP_BUCKET__AGGREGATOR_SCRAPER"                    = "gs://${data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-aggregator-scraper_name}",
        "CALITP_BUCKET__AIRTABLE"                              = "gs://${data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-airtable_name}",
        "CALITP_BUCKET__AMPLITUDE_BENEFITS_EVENTS"             = "gs://${data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-amplitude-benefits-events_name}",
        "CALITP_BUCKET__ANALYSIS_OUTPUT_MODELS"                = "gs://${data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-analysis-output-models_name}",
        "CALITP_BUCKET__DBT_ARTIFACTS"                         = "gs://${data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-dbt-artifacts_name}",
        "CALITP_BUCKET__DBT_DOCS"                              = "gs://${data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-dbt-docs_name}",
        "CALITP_BUCKET__ELAVON_PARSED"                         = "gs://${data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-elavon-parsed_name}",
        "CALITP_BUCKET__ELAVON_RAW"                            = "gs://${data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-elavon-raw_name}",
        "CALITP_BUCKET__GTFS_DOWNLOAD_CONFIG"                  = "gs://${data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-gtfs-download-config_name}",
        "CALITP_BUCKET__GTFS_DOWNLOAD_CONFIG_PROD_SOURCE"      = "gs://${data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-gtfs-download-config_name}",
        "CALITP_BUCKET__GTFS_DOWNLOAD_CONFIG_TEST_DESTINATION" = "gs://${data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-gtfs-download-config-test_name}",
        "CALITP_BUCKET__GTFS_RT_PARSED"                        = "gs://${data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-gtfs-rt-parsed_name}",
        "CALITP_BUCKET__GTFS_RT_RAW"                           = "gs://${data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-gtfs-rt-raw-v2_name}",
        "CALITP_BUCKET__GTFS_RT_VALIDATION"                    = "gs://${data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-gtfs-rt-validation_name}",
        "CALITP_BUCKET__GTFS_SCHEDULE_PARSED"                  = "gs://${data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-gtfs-schedule-parsed_name}",
        "CALITP_BUCKET__GTFS_SCHEDULE_PARSED_HOURLY"           = "gs://${data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-gtfs-schedule-parsed-hourly_name}",
        "CALITP_BUCKET__GTFS_SCHEDULE_RAW"                     = "gs://${data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-gtfs-schedule-raw-v2_name}",
        "CALITP_BUCKET__GTFS_SCHEDULE_UNZIPPED"                = "gs://${data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-gtfs-schedule-unzipped_name}",
        "CALITP_BUCKET__GTFS_SCHEDULE_UNZIPPED_HOURLY"         = "gs://${data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-gtfs-schedule-unzipped-hourly_name}",
        "CALITP_BUCKET__GTFS_SCHEDULE_VALIDATION"              = "gs://${data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-gtfs-schedule-validation_name}",
        "CALITP_BUCKET__GTFS_SCHEDULE_VALIDATION_HOURLY"       = "gs://${data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-gtfs-schedule-validation-hourly_name}",
        "CALITP_BUCKET__KUBA"                                  = "gs://${data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-kuba_name}",
        "CALITP_BUCKET__LITTLEPAY_PARSED"                      = "gs://${data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-payments-littlepay-parsed_name}",
        "CALITP_BUCKET__LITTLEPAY_PARSED_V3"                   = "gs://${data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-payments-littlepay-parsed-v3_name}",
        "CALITP_BUCKET__LITTLEPAY_RAW"                         = "gs://${data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-payments-littlepay-raw_name}",
        "CALITP_BUCKET__LITTLEPAY_RAW_V3"                      = "gs://${data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-payments-littlepay-raw-v3_name}",
        "CALITP_BUCKET__NTD_API_DATA_PRODUCTS"                 = "gs://${data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-ntd-api-products_name}",
        "CALITP_BUCKET__NTD_REPORT_VALIDATION"                 = "gs://${data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-ntd-report-validation_name}",
        "CALITP_BUCKET__NTD_XLSX_DATA_PRODUCTS__CLEAN"         = "gs://${data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-ntd-xlsx-products-clean_name}",
        "CALITP_BUCKET__NTD_XLSX_DATA_PRODUCTS__RAW"           = "gs://${data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-ntd-xlsx-products-raw_name}",
        "CALITP_BUCKET__PUBLISH"                               = "gs://${data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-publish_name}",
        "CALITP_BUCKET__SENTRY_EVENTS"                         = "gs://${data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-sentry_name}",
        "CALITP_BUCKET__STATE_GEOPORTAL_DATA_PRODUCTS"         = "gs://${data.terraform_remote_state.gcs.outputs.google_storage_bucket_calitp-state-geoportal-scrape_name}",
        "CALITP_SLACK_URL"                                     = data.google_secret_manager_secret_version.slack-airflow-url.secret_data
        "CALITP_NOTIFY_EMAIL"                                  = "dds.app.notify@dot.ca.gov"
      })
    }
  }
}
