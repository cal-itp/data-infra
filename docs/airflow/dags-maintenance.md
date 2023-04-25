(dags-maintenance)=
# Production DAGs Maintenance

_Last edited: May 5, 2022_

## Re-running or clearing DAGs

Sometimes DAGs will fail in production. Below are considerations to take into account when re-running or clearing DAGs to address failures.

There are roughly two categories of Airflow DAGs in our system.
* "Now" DAGs - mostly for executing code on a schedule (often scraping current data, or a fancy cron job), NOT orchestrating distributed processing of existing data
  * **When these DAGs fail, and you'd like to re-run them, you should execute a new manual run rather than clearing a historical run.**
  * Only the actual execution time matters if relevant (usually for timestamping data or artifacts)
  * Generally safe but not useful to execute multiple times simultaneously
  * There is no concept of backfilling via these DAGs; they may output data/artifacts that require "backfilling" (i.e. modifying existing data) via a script or notebook
* "Data interval processing" DAGs - orchestrates processing of previously-captured data, or data than can be retrieved in a timestamped manner (e.g. Amplitude)
  * **When these DAGs fail, you should clear the historical task instances that failed.** (Generally, these DAGs are expected to be 100% successful.)
  * Relies heavily on the `execution_date` or `data_interval_start/end` concepts
  * May not be entirely idempotent though we try; for example, validating RT data depends on Schedule data which may be late-arriving
  * Backfilling can generally be performed by clearing past task instances and letting them re-run
  * We try to avoid `depends_on_past` DAGs, so parallelization is possible during backfills

DAGs are listed in alphabetical order (like in the Airflow UI) and are labeled by

| DAG                                | "Now" | Notes                                                                                                                                                                                                 |
|------------------------------------|-------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `airtable_loader_v2`               | Yes   | Don't need to rerun more than once if multiple failures; scraped data is labeled by actual execution time                                                                                             |
| `amplitude_benefits`               | No    | This will be replaced soon by an Amplitude-to-GCS export.                                                                                                                                             |
| `create_external_tables`           | Yes   | Generally only fails due to GCP issues or definition problems; individual tasks can be cleared once fixed                                                                                             |
| `deploy_dbt_docs`                  | Yes   | Manual job to deploy dbt docs to Metabase and Netlify                                                                                                                                                 |
| `download_gtfs_schedule_v2`        | Yes   | Don't need to rerun more than once if multiple failures; scraped data is labeled by actual execution time                                                                                             |
| `parse_and_validate_rt_v2`         | No    |                                                                                                                                                                                                       |
| `payments_loader`                  | Yes   | This is deprecated, pending data consumers switching to v2 models. See below for maintenance.                                                                                                         |
| `scrape_feed_aggregators`          | Yes   | Scraped data is labeled by actual execution time                                                                                                                                                      |
| `transform_warehouse`              | Yes   | Configurable via JSON task parameters to run a portion of the DAG (`dbt_select_statement` key); outputs timestamped artifacts                                                                         |
| `transform_warehouse_full_refresh` | Yes   | Manual job to execute a full-refresh dbt job; should be used sparingly; configurable via JSON task parameters to run a portion of the DAG (`dbt_select_statement` key); outputs timestamped artifacts |
| `unzip_and_validate_gtfs_schedule` | No    |                                                                                                                                                                                                       |

### GTFS Realtime parsing and validation
The primary DAG relevant to GTFS Realtime data is [parse_and_validate_rt_v2](https://github.com/cal-itp/data-infra/tree/main/airflow/dags/parse_and_validate_rt_v2).
This DAG parses RT files into JSONL and writes them to GCS for querying via BigQuery external tables.
It also executes the [realtime validator](https://github.com/MobilityData/gtfs-realtime-validator)
against the RT files and writes the validation notices as JSONL to GCS for querying.

The raw proto files themselves are fetched via [the archiver](https://github.com/cal-itp/data-infra/tree/main/services/gtfs-rt-archiver-v3).

### Deprecated DAGs

The following DAGs are still listed in the Airflow UI even though they are **deprecated or indefinitely paused**. They never need to be re-run.

* `check_data_freshness`

## Task-level considerations

Some tasks have unique considerations, beyond the requirements of their overall DAG.

* **`PodOperators`**: When restarting a failed `PodOperator` run, check the logs before restarting. If the logs show any indication that the prior run's pod was not killed (for example, if the logs cut off abruptly without showing an explicit task failure), you should check that the pod associated with the failed run task has in fact been killed before clearing or restarting the Airflow task. If you don't know how to check a pod status, please ask in the `#data-infra` channel on Slack before proceeding.

## Backfilling from the command line

From time-to-time some DAGs may need to be re-ran in order to populate new data.

Subject to the considerations outlined abov, backfilling can be performed by clearing historical runs in the web interface, or via the CLI:
```shell
gcloud composer environments run calitp-airflow-prod --location=us-west2 backfill -- --start_date 2021-04-18 --end_date 2021-11-03 -x --reset_dagruns -y -t "gtfs_schedule_history_load" -i gtfs_loader
```

## Legacy Payments

The ETL is currently a scheduled Google Data Transfer job that transfers all files to `gcs://littlepay-data-extract-prod`, and parse jobs that transfer those files into the location read by BigQuery's external tables (only keeping relevant columns).

### DAGs Overview

The payments data is loaded and transformed in the payments_loader DAG.

The payments_loader dag has three kinds of tasks:

* ExternalTable operator tasks (e.g. `customer_funding_source`). These define the underlying data.
* `calitp_included_payments_data` - a table of underlying payments table names defined in the task above.
* `preprocessing_columns` - move data from `gs://littlepay-data-extract-prod` to `gs://gtfs-data`,
  then process to keep only columns defined in external tables.
