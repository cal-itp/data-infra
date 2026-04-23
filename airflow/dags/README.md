# DAGs

| Time_in_UTC | Time_in_PST          | Time_in_PDT          | DAG                                                                                                                              | Schedule   |
|   :---:     | :---:                | :---:                |:---                                                                                                                              | :---:      |
|  0:00 AM    | 4 PM<br>previous day | 5 PM<br>previous day | [publish_gtfs](#publish_gtfs)                                                                                                    | Mondays    |
|  0:00 AM    | 4 PM<br>previous day | 5 PM<br>previous day | [sync_elavon](./sync_elavon)<br>[sync_kuba](./sync_kuba)<br>[scrape_feed_aggregators](./scrape_feed_aggregators)<br>[copy_production_to_staging](./copy_production_to_staging) | Every day  |
|  2:00 AM    | 6 PM<br>previous day | 7 PM<br>previous day | [airtable_loader_v2](./airtable_loader_v2)<br>[parse_elavon](./parse_elavon)                                                     | Every Day  |
|  3:00 AM    | 7 PM<br>previous day | 8 PM<br>previous day | [download_parse_and_validate_gtfs](#download_parse_and_validate_gtfs)                                                            | Every Day  |
|  4:00 AM    | 8 PM<br>previous day | 9 PM<br>previous day | [scrape_state_geoportal](./scrape_state_geoportal)                                                                               | 1st Day of the month |
|  9:00 AM    | 1:00 AM              | 2:00 AM              | [sync_ntd_data_api](./sync_ntd_data_api)                                                                                         | Wednesdays |
| 10:00 AM    | 2:00 AM              | 3:00 AM              | [ntd_report_from_blackcat](./ntd_report_from_blackcat)<br>[download_and_parse_ntd_xlsx](#download_and_parse_ntd_xlsx)            | Mondays    |
| 11:00 AM    | 3:00 AM              | 4:00 AM              | [create_external_tables](./create_external_tables)                                                                               | Every Day  |
| 12:00 PM    | 4:00 AM              | 5:00 AM              | [download_and_parse_littlepay](#download_and_parse_littlepay)                                                                    | Every Day  |
|             | Every Hour           |                      | [sync_littlepay_v3](./sync_littlepay_v3)                                                                                         | Every Day  |
|             | Every<br>Hour:30 min                       || [parse_littlepay_v3](./parse_littlepay_v3)                                                                                       | Every Day  |
|             | Every<br>Hour:15 min                       || [parse_and_validate_rt](#parse_and_validate_rt)                                                                                  | Every Day  |
|  2:00 PM    | 6:00 AM              | 7:00 AM              | [dbt_all](#dbt_all)                                                                                                              | Monday and Thursday |
|  2:00 PM    | 6:00 AM              | 7:00 AM              | [dbt_daily](#dbt_daily)                                                                                                          | Sunday, Tuesday, Wednesday, Friday, and Saturday |
|  2:00 PM    | 6:00 AM              | 6:00 AM              | [airtable_issue_management](#airtable_issue_management)                                                                          | Fridays    |
|  -          | -                    | -                    | [dbt_manual](#dbt_manual)                                                                                                        | Runs Only Manually |

## dbt_all

   Runs all dbt models on **Mondays** and **Thursdays**.


## dbt_daily

   Runs specific dbt models on the days that are not covered by `dbt_all` (**Sundays**, **Tuesdays**, **Wednesdays**, **Fridays**, and **Saturdays**).


## dbt_manual

   Runs specific dbt models as needed. It needs to be triggered manually.


## download_and_parse_littlepay
> [!NOTE]
> This DAG replaces [sync_littlepay_v3](./sync_littlepay_v3) and [parse_littlepay_v3](./parse_littlepay_v3).

   This DAG orchestrates the syncing and parsing of raw Littlepay feed v3 data.

   The data is usually available in the S3 bucket at 12 PM UTC (4 AM PST / 5 AM PDT).

   See more information about Littlepay in [Cal-ITP Payments Data Ecosystem Documentation](https://github.com/cal-itp/data-infra/tree/main/runbooks/workflow/payments).


## download_and_parse_ntd_xlsx

   This DAG downloads NTD excel files (xslx) from `Federal Transit Administration` website and converts into BigQuery-readable gzipped JSONL files.

   The `create_external_tables` DAG reads these jsonl files and creates external tables in the Cal-ITP data warehouse (BigQuery) and `dbt_all` and `dbt_manual` DAGs updates all downstream models.


## download_parse_and_validate_gtfs

### 1. Generates GTFS Config Files (datasets)

  Runs [**BigQueryToDownloadConfigOperator**](airflow/plugins/operators/bigquery_to_download_config_operator.py).

   - Downloads datasets from bigquery table `staging.int_gtfs_datasets`.

         Data source lineage:
            airtable.california_transit__gtfs_datasets
               -> staging.stg_transit_database__gtfs_datasets
                  -> staging.int_transit_database__gtfs_datasets_dim


   - For each dataset:
      * Selects records that are data quality pipeline (`data_quality_pipeline IS TRUE`), are current (`_is_current IS TRUE`), and are not deprecated (`deprecated_date IS NULL`)
      * Builds query and header params if exists in the config
      * Maps the URI for schedule validation through `schedule_to_use_for_rt_validation`
      * Zips config results


  - Uploads zipped config files to `gs://{CALITP_BUCKET__GTFS_DOWNLOAD_CONFIG}/gtfs_download_configs/dt={DATE}/ts={UTC_TIMESTAMP}/configs.jsonl.gz`.

    To visualize the raw data from these files, you can query **external_gtfs_schedule.download_configs** or **mart_gtfs_audit.dim_gtfs_download_config** in BigQuery.


### 2. Downloads Dataset Zip Files

   - Runs [**GCSDownloadConfigFilterOperator**](airflow/plugins/operators/gcs_download_config_filter_operator.py) to filter for schedule datasets from the previous step.

   - Runs [**DownloadConfigToGCSOperator**](airflow/plugins/operators/download_config_to_gcs_operator.py) and [**DownloadConfigHook**](airflow/plugins/hooks/download_config_hook.py).

> [!NOTE]
> This process will try to download files from `Manual Download Bucket` first

   + Downloads a zip file for each schedule dataset.
      * Adds default headers
      * Replaces key params by specific secret values (old process sends all secrets to each dataset)
      * Allows redirects
      * Encodes url to base64 url
      * Adds PARTITIONED_ARTIFACT_METADATA to files

   + Uploads successfull zip files downloaded to `gs://{CALITP_BUCKET__GTFS_SCHEDULE_RAW}/schedule/dt={DATE}/ts={UTC_TIMESTAMP}/base64_url={base64_url}/{file_name}.zip`.

   + Uploads summary results for each dataset to `gs://{CALITP_BUCKET__GTFS_SCHEDULE_RAW}/gtfs_download_configs/dt={DATE}/ts={UTC_TIMESTAMP}/{base64_url}.jsonl`.
        The v2 process generates a unique file (`results.jsonl`) containing the summary for all datasets.
        To visualize the raw data from these files, you can query **external_gtfs_schedule.download_outcomes** or **mart_gtfs_audit.dim_gtfs_schedule_download_outcomes** in BigQuery.


   To add manually downloaded zip files:
   1. Go to [download_parse_and_validate_gtfs](https://b15efed84aa34881b71da3b8fa87acd6-dot-us-west2.composer.byoid.googleusercontent.com/dags/download_parse_and_validate_gtfs/grid) DAG
   2. Click on `download_config_to_gcs` task, then `Mapped Tasks` tab
   3. Click on the dataset that you want to add a zip file
   4. Click on `Details` tab
   5. Copy the `base64_url` and `url` information (`url` is located inside `download_config`)
   6. Download the file using the `url` from step 5
   7. Upload the zip file to `gs://{CALITP_BUCKET__GTFS_SCHEDULE_MANUAL}/manual/<base64_url>`, replacing <base64_url> with the `base64_url` from step 5


### 3. Validates files

   Runs [**ValidateGTFSToGCSOperator**](airflow/plugins/operators/validate_gtfs_to_gcs_operator.py) and [**GTFSValidatorHook**](airflow/plugins/hooks/gtfs_validator_hook.py).

   - Validates zip files downloaded on `download_gtfs` DAG.

   - Uploads notices from the validator, if any, to `gs://{CALITP_BUCKET__GTFS_SCHEDULE_VALIDATION_HOURLY}/validation_notices/t={DATE}/ts={UTC_TIMESTAMP}/base64_url={base64_url}/validation_notices_v{version}.jsonl.gz`.
      * Adds PARTITIONED_ARTIFACT_METADATA to files

      To visualize the raw data from these files, you can query **external_gtfs_schedule.validation_notices**, **staging.stg_gtfs_schedule__validation_notices**, or **mart_gtfs_audit.dim_gtfs_schedule_validation_notices** in BigQuery.


   - Uploads summary results for each dataset to `gs://{CALITP_BUCKET__GTFS_SCHEDULE_RAW}/validation_job_results/dt={DATE}/ts={UTC_TIMESTAMP}/{base64_url}.jsonl`.
      * Adds PARTITIONED_ARTIFACT_METADATA to files

     The v2 process generates a unique file (`results.jsonl`) containing the summary for all datasets.
     To visualize the raw data from these files, you can query **external_gtfs_schedule.validations_outcomes**, **staging.stg_gtfs_schedule__validation_outcomes**, or **mart_gtfs_audit.dim_gtfs_schedule_validation_outcomes** in BigQuery.


### 4. Unzips and Convert Dataset Files

#### 4.1. Unzips Dataset Files

   Runs [**UnzipGTFSToGCSOperator**](airflow/plugins/operators/unzip_gtfs_to_gcs_operator.py) and [**GTFSUnzipHook**](airflow/plugins/hooks/gtfs_unzip_hook.py).

   - Unzips downloaded files from `download_gtfs` DAG.

   - Extracts allowed `txt` files to `csv`:
      * agency
      * areas
      * attributions
      * calendar
      * calendar_dates
      * fare_attributes
      * fare_leg_rules
      * fare_media
      * fare_products
      * fare_rules
      * fare_transfer_rules
      * feed_info
      * frequencies
      * levels
      * pathways
      * routes
      * shapes
      * stop_areas
      * stop_times
      * stops
      * transfers
      * translations
      * trips


   - Uploads each extracted file (csv format) to `gs://{CALITP_BUCKET__GTFS_SCHEDULE_UNZIPPED_HOURLY}/{filename}.txt/dt={DATE}/ts={UTC_TIMESTAMP}/base64_url={base64_url}/{filename}.txt`.
      * Adds PARTITIONED_ARTIFACT_METADATA to files

      The v2 process uploads files in txt format.


   - Uploads summary results for each dataset to `gs://{CALITP_BUCKET__GTFS_SCHEDULE_UNZIPPED_HOURLY}/unzipping_results/dt={DATE}/ts={UTC_TIMESTAMP}/{base64_url}.jsonl`.
      * Adds PARTITIONED_ARTIFACT_METADATA to files

      The v2 process generates a unique file (`results.jsonl`) containing the summary for all datasets.
      To visualize the raw data from these files, you can query **external_gtfs_schedule.unzip_outcomes**, **staging.stg_gtfs_schedule__unzip_outcomes**, or **mart_gtfs_audit.dim_gtfs_schedule_unzip_outcomes** in BigQuery.

#### 4.2. Converts files to external tables format (jsonl)

   Runs [**GTFSCSVToJSONLOperator**](airflow/plugins/operators/gtfs_csv_to_jsonl_operator.py).

   - Converts each csv file from each dataset to jsonl.

   - Uploads each jsonl file to `gs://{CALITP_BUCKET__GTFS_SCHEDULE_PARSED_HOURLY}/{filename}/dt={DATE}/ts={UTC_TIMESTAMP}/base64_url={base64_url}/{filename}.jsonl.gz`.
      * Adds PARTITIONED_ARTIFACT_METADATA to files

      To visualize the raw data from these files, you can query **external_gtfs_schedule.{filename}** or **staging.stg_gtfs_schedule__{filename}** in BigQuery.

   - Uploads summary results for each dataset to `gs://{CALITP_BUCKET__GTFS_SCHEDULE_PARSED_HOURLY}/{filename}.txt_parsing_results/dt={DATE}/ts={UTC_TIMESTAMP}/{base64_url}.jsonl`.
      * Adds PARTITIONED_ARTIFACT_METADATA to files

      The v2 process generates a unique file (`results.jsonl`) containing the summary for all datasets.
      To visualize the raw data from these files, you can query **external_gtfs_schedule.{filename}\_txt_parse_outcomes** or **staging.stg_gtfs_schedule__file_parse_outcomes** in BigQuery.


## parse_and_validate_rt

   This DAG orchestrates the parsing and validation of GTFS RT data downloaded by the [archiver](../../services/gtfs-rt-archiver-v3/README.md).


## publish_gtfs

   This DAG orchestrates the publishing of data from the Cal-ITP data warehouse to the California Open Data Portal. Failures in this job may require coordination with the central data portal team if there is an issue with CKAN itself.

## airtable_issue_management

This DAG automates the lifecycle management of Transit Data Quality (TDQ) issues related to GTFS feed expiration. It handles both:

- closing issues that are no longer relevant
- creating new issues for feeds that require attention

This helps keep Airtable synchronized with the current state of GTFS data quality.


### Workflows Overview

   The DAG consists of two main workflows executed in parallel.


### 1. Close Expired Issues (`close_expired_issues`)

   This workflow identifies Airtable issues that should be closed and updates them accordingly.

   - Reads candidate records from dbt model `fct_close_expired_issues`.

         Data source:
            fct_close_expired_issues

   - Identifies GTFS datasets where:
      * the feed is no longer expired or no longer within the expiration window
      * an open Airtable issue still exists

   - Updates corresponding Airtable records:
      * Marks issues as resolved
      * Performs batch updates for efficiency


### 2. Create Expiring Issues (`create_expiring_issues`)

   This workflow identifies GTFS datasets that require new Airtable issues.

   - Reads candidate records from dbt model `fct_create_expiring_gtfs_issues`.

         Data source:
            fct_create_expiring_gtfs_issues

   - Identifies GTFS datasets where:
      * the feed is expired or expiring within 30 days
      * no open Airtable issue currently exists

   - Creates new Airtable records:
      * Applies standardized fields (Issue Type, Status, Outreach Status, etc.)
      * Associates GTFS datasets and services
      * Populates description and tracking fields


### 3. Sends Summary Email

   This workflow sends a consolidated HTML email summarizing the results of both workflows.

   - Includes:
      * Number of records updated (closed issues)
      * Number of records created (new issues)
      * Tables listing affected records
      * Any failed batch operations

   - Additional behavior:
      * When new issues are created, individual emails are sent per record
      * A HubSpot notification section is included in the summary email


### DAG Structure

   Uses LatestOnlyOperator to ensure only the most recent scheduled run executes.

   Workflow structure:

      latest_only
         close_expired_issues
            ├── bq_close_expired_issues_candidates
            └── update_airtable_issues

         create_expiring_issues
            ├── bq_create_expiring_issues_candidates
            └── create_airtable_issues

      close_expired_issues + create_expiring_issues
         └── send_airtable_issue_email


### Scheduling

   - Runs weekly in Composer
   - Designed for recurring monitoring and maintenance of GTFS data quality


### Design Notes

   - Uses custom operators and hooks for:
      * BigQuery reads
      * Airtable updates and creates
      * Email notifications

   - Separates:
      * data retrieval (BigQuery)
      * business logic (operators)
      * side effects (Airtable and email)

   - Consolidates notifications into a single email to avoid alert fatigue


### Troubleshooting

   No email sent:
      - Check whether both workflows returned zero rows
      - Email is skipped when there are no updates or creations

   Missing Airtable updates or creations:
      - Verify dbt models:
         * `fct_close_expired_issues`
         * `fct_create_expiring_gtfs_issues`
      - Confirm dataset and table names in operator configuration

   Partial failures (batch errors):
      - Review the failed batch section in the email
      - Check Airflow logs for the corresponding task

   Individual emails not sent:
      - Ensure `HUBSPOT_NOTIFICATION_EMAIL` is set
      - Verify that new records were actually created


### When to Use This DAG Pattern

   This DAG is a good example of when Airflow is appropriate:

   - Recurring, scheduled workflows
   - Multi-step pipelines with dependencies
   - External system integration across BigQuery, Airtable, and email
   - Workflows that require monitoring, logging, and retry behavior

   Simpler approaches (such as notebooks or scripts) may be more appropriate for:
   - one-off analyses
   - exploratory workflows
   - tasks that do not require scheduling or orchestration

## Testing DAGs

   To run and test DAGs use [Airflow Staging](https://23aa69a214bb410fba28ad96dd552748-dot-us-west2.composer.byoid.googleusercontent.com/home) or [composer-local-dev](https://github.com/cal-itp/data-infra/tree/main/airflow#local-development) to run locally.

### Automated Tests

   Each operator and hook file have pytest under `airflow/tests/` folder. Go to [running-automated-tests](https://github.com/cal-itp/data-infra/tree/main/airflow#running-automated-tests) for more information.
