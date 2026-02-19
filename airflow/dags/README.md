# DAGs

| Time_in_UTC | Time_in_PST          | Time_in_PDT          | DAG                                                                                                                              | Schedule   |
|   :---:     | :---:                | :---:                |:---                                                                                                                              | :---:      |
|  0:00 AM    | 4 PM<br>previous day | 5 PM<br>previous day | [publish_gtfs](#publish_gtfs)                                                                                                    | Mondays    |
|  0:00 AM    | 4 PM<br>previous day | 5 PM<br>previous day | [sync_elavon](./sync_elavon)(<br>[sync_kuba](./sync_kuba)<br>[scrape_feed_aggregators](./scrape_feed_aggregators)<br>[copy_production_to_staging](./copy_production_to_staging) | Every day  |
|  2:00 AM    | 6 PM<br>previous day | 7 PM<br>previous day | [airtable_loader_v2](./airtable_loader_v2)<br>[parse_elavon](./parse_elavon)                                                     | Every Day  |
|  3:00 AM    | 7 PM<br>previous day | 8 PM<br>previous day | [download_parse_and_validate_gtfs](#download_parse_and_validate_gtfs)                                                            | Every Day  |
|  4:00 AM    | 8 PM<br>previous day | 9 PM<br>previous day | [scrape_state_geoportal](./scrape_state_geoportal)                                                                               | 1st Day of the month |
|  9:00 AM    | 1:00 AM              | 2:00 AM              | [sync_ntd_data_api](./sync_ntd_data_api)                                                                                         | Wednesdays |
| 10:00 AM    | 2:00 AM              | 3:00 AM              | [ntd_report_from_blackcat](./ntd_report_from_blackcat)<br>[sync_ntd_data_xlsx](./sync_ntd_data_xlsx)                             | Mondays    |
| 11:00 AM    | 3:00 AM              | 4:00 AM              | [create_external_tables](./create_external_tables)                                                                               | Every Day  |
|             | Every Hour           |                      | [sync_littlepay_v3](./sync_littlepay_v3)                                                                                         | Every Day  |
|             | Every<br>Hour:30 min                       || [parse_littlepay_v3](./parse_littlepay_v3)                                                                                       | Every Day  |
|             | Every<br>Hour:15 min                       || [parse_and_validate_rt](#parse_and_validate_rt)                                                                                  | Every Day  |
|  2:00 PM    | 6:00 AM              | 7:00 AM              | [dbt_all](#dbt_all)                                                                                                              | Monday and Thursday |
|  2:00 PM    | 6:00 AM              | 7:00 AM              | [dbt_daily](#dbt_daily)                                                                                                          | Sunday, Tuesday, Wednesday, Friday, and Saturday |
|  -          | -                    | -                    | [dbt_manual](#dbt_manual)<br>[download_gtfs_schedule_v2](./download_gtfs_schedule_v2)<br>[unzip_and_validate_gtfs_schedule_hourly](./unzip_and_validate_gtfs_schedule_hourly)| Runs Only Manually |


## dbt_all

   Runs all dbt models on **Mondays** and **Thursdays**.


## dbt_daily

   Runs specific dbt models on the days that are not covered by `dbt_all` (**Sundays**, **Tuesdays**, **Wednesdays**, **Fridays**, and **Saturdays**).


## dbt_manual

   Runs specific dbt models as needed. It needs to be triggered manually.


## download_parse_and_validate_gtfs

### 1. Generates GTFS Config Files (datasets)

  Runs [**BigQueryToDownloadConfigOperator**](airflow/plugins/operators/bigquery_to_download_config_operator.py) replacing [generate_gtfs_download_configs.py](airflow/dags/airtable_loader_v2/generate_gtfs_download_configs.py) and [storage.py](airflow/plugins/calitp_data_infra/storage.py).

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

   - Runs [**DownloadConfigToGCSOperator**](airflow/plugins/operators/download_config_to_gcs_operator.py) and [**DownloadConfigHook**](airflow/plugins/hooks/download_config_hook.py) replacing [download_gtfs_schedule_v2 DAG](airflow/dags/download_gtfs_schedule_v2).

      + Tries to download a zip file for each schedule dataset.
         * Adds default headers
         * Replaces key params by specific secret values (old process sends all secrets to each dataset)
         * Allows redirects
         * Encodes url to base64 url
         * Adds PARTITIONED_ARTIFACT_METADATA to files

      + Uploads successfull zip files downloaded to `gs://{CALITP_BUCKET__GTFS_SCHEDULE_RAW}/schedule/dt={DATE}/ts={UTC_TIMESTAMP}/base64_url={base64_url}/{file_name}.zip`.

      + Uploads summary results for each dataset to `gs://{CALITP_BUCKET__GTFS_SCHEDULE_RAW}/gtfs_download_configs/dt={DATE}/ts={UTC_TIMESTAMP}/{base64_url}.jsonl`.
           The v2 process generates a unique file (`results.jsonl`) containing the summary for all datasets.
           To visualize the raw data from these files, you can query **external_gtfs_schedule.download_outcomes** or **mart_gtfs_audit.dim_gtfs_schedule_download_outcomes** in BigQuery.



### 3. Validates files

   Runs [**ValidateGTFSToGCSOperator**](airflow/plugins/operators/validate_gtfs_to_gcs_operator.py) and [**GTFSValidatorHook**](airflow/plugins/hooks/gtfs_validator_hook.py) replacing [unzip_and_validate_gtfs_schedule_hourly.validate_gtfs_schedule](airflow/dags/unzip_and_validate_gtfs_schedule_hourly/validate_gtfs_schedule.yml).

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

   Runs [**UnzipGTFSToGCSOperator**](airflow/plugins/operators/unzip_gtfs_to_gcs_operator.py) and [**GTFSUnzipHook**](airflow/plugins/hooks/gtfs_unzip_hook.py) replacing [unzip_and_validate_gtfs_schedule_hourly.unzip_gtfs_schedule](airflow/dags/unzip_and_validate_gtfs_schedule_hourly/unzip_gtfs_schedule.py).

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

   Runs [**GTFSCSVToJSONLOperator**](airflow/plugins/operators/gtfs_csv_to_jsonl_operator.py) replacing [unzip_and_validate_gtfs_schedule_hourly.convert_to_json](airflow/dags/unzip_and_validate_gtfs_schedule_hourly/convert_to_json).

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
