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
      }

      pypi_packages = local.pypi_packages

      env_variables = {
        AIRFLOW_VAR_EXTRACT_BUCKET                           = "gs://gtfs-data"
        AIRFLOW_ENV                                          = "cal-itp-data-infra-staging"
        GOOGLE_CLOUD_PROJECT                                 = "cal-itp-data-infra-staging"
        CALITP_USER                                          = "pipeline"
        CALITP_AUTH                                          = "cloud"
        CALITP_BQ_MAX_BYTES                                  = "50000000000"
        POD_CLUSTER_NAME                                     = "us-west2-calitp-airflow2-pr-91e4038b-gke"
        POD_LOCATION                                         = "us-west2-a"
        CALITP_BUCKET__AIRTABLE                              = "gs://calitp-staging-airtable"
        CALITP_BUCKET__GTFS_RT_RAW                           = "gs://calitp-staging-gtfs-rt-raw-v2"
        CALITP_BUCKET__GTFS_RT_PARSED                        = "gs://calitp-staging-gtfs-rt-parsed"
        CALITP_BUCKET__GTFS_RT_VALIDATION                    = "gs://calitp-staging-gtfs-rt-validation"
        CALITP_BUCKET__GTFS_SCHEDULE_RAW                     = "gs://calitp-staging-gtfs-schedule-raw-v2"
        CALITP_BUCKET__GTFS_SCHEDULE_VALIDATION              = "gs://calitp-staging-gtfs-schedule-validation"
        CALITP_BUCKET__GTFS_SCHEDULE_UNZIPPED                = "gs://calitp-staging-gtfs-schedule-unzipped"
        DBT_TARGET                                           = "staging_service_account"
        CALITP_BUCKET__PUBLISH                               = "gs://calitp-staging-publish"
        CALITP_BUCKET__DBT_ARTIFACTS                         = "gs://calitp-staging-dbt-artifacts"
        CALITP_BUCKET__GTFS_SCHEDULE_PARSED                  = "gs://calitp-staging-gtfs-schedule-parsed"
        CALITP_BUCKET__GTFS_DOWNLOAD_CONFIG                  = "gs://calitp-staging-gtfs-download-config"
        SENTRY_DSN                                           = "https://0fc56e5e8a96482da63b8d9dd3955ee7@sentry.k8s.calitp.jarv.us/2"
        SENTRY_ENVIRONMENT                                   = "cal-itp-data-infra-staging"
        CALITP_BUCKET__AGGREGATOR_SCRAPER                    = "gs://calitp-staging-aggregator-scraper"
        CALITP_BUCKET__SENTRY_EVENTS                         = "gs://test-calitp-sentry"
        CALITP_BUCKET__LITTLEPAY_RAW                         = "gs://calitp-staging-payments-littlepay-raw"
        CALITP_BUCKET__LITTLEPAY_PARSED                      = "gs://calitp-staging-payments-littlepay-parsed"
        CALITP_BUCKET__ELAVON_RAW                            = "gs://calitp-staging-elavon-raw"
        CALITP_BUCKET__ELAVON_PARSED                         = "gs://calitp-staging-elavon-parsed"
        CALITP__ELAVON_SFTP_HOSTNAME                         = "34.145.56.125"
        CALITP__ELAVON_SFTP_PORT                             = "2200"
        CALITP__ELAVON_SFTP_USERNAME                         = "elavon"
        CALITP_BUCKET__GTFS_SCHEDULE_VALIDATION_HOURLY       = "gs://calitp-staging-gtfs-schedule-validation-hourly"
        CALITP_BUCKET__GTFS_SCHEDULE_UNZIPPED_HOURLY         = "gs://calitp-staging-gtfs-schedule-unzipped-hourly"
        CALITP_BUCKET__GTFS_SCHEDULE_PARSED_HOURLY           = "gs://calitp-staging-gtfs-schedule-parsed-hourly"
        CALITP_BUCKET__AMPLITUDE_BENEFITS_EVENTS             = "gs://calitp-staging-amplitude-benefits-events"
        CALITP_BUCKET__GTFS_DOWNLOAD_CONFIG_PROD_SOURCE      = "gs://calitp-staging-gtfs-download-config"
        CALITP_BUCKET__GTFS_DOWNLOAD_CONFIG_TEST_DESTINATION = "gs://test-calitp-gtfs-download-config"
        CALITP_BUCKET__NTD_XLSX_DATA_PRODUCTS__RAW           = "gs://calitp-staging-ntd-xlsx-products-raw"
        CALITP_BUCKET__NTD_XLSX_DATA_PRODUCTS__CLEAN         = "gs://calitp-staging-ntd-xlsx-products-clean"
        CALITP_BUCKET__NTD_API_DATA_PRODUCTS                 = "gs://calitp-staging-ntd-api-products"
        CALITP_BUCKET__STATE_GEOPORTAL_DATA_PRODUCTS         = "gs://calitp-staging-state-geoportal-scrape"
        CALITP_BUCKET__LITTLEPAY_RAW_V3                      = "gs://calitp-staging-payments-littlepay-raw-v3"
        CALITP_BUCKET__LITTLEPAY_PARSED_V3                   = "gs://calitp-staging-payments-littlepay-parsed-v3"
      }
    }
  }
}
