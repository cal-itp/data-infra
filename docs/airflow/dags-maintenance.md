# DAGs Maintenance

## GTFS Realtime - DAGs Maintenance

### DAGs Overview

The primary DAG relevant to GTFS Realtime data is [parse_and_validate_rt_v2](https://github.com/cal-itp/data-infra/tree/main/airflow/dags/parse_and_validate_rt_v2).
This DAG parses RT files into JSONL and writes them to GCS for querying via BigQuery external tables.
It also executes the [realtime validator](https://github.com/MobilityData/gtfs-realtime-validator)
against the RT files and writes the validation notices as JSONL to GCS for querying.

The raw proto files themselves are fetched via [the archiver](https://github.com/cal-itp/data-infra/tree/main/services/gtfs-rt-archiver-v3).

### Backfilling

This DAG does not have any tasks that `depends_on_past`, so you should be able to
clear and re-run tasks as needed.

## MST Payments - DAGs Maintenance

The ETL is currently a scheduled Google Data Transfer job that transfers all files to `gcs://littlepay-data-extract-prod`

From there, tables are loaded into BigQuery as external tables in the `transaction_data` buclet.

### DAGs Overview

The payments data is loaded and transformed in the payments_loader DAG.

The payments_loader dag has three kinds of tasks:

* ExternalTable operator tasks (e.g. `customer_funding_source`). These define the underlying data.
* `calitp_included_payments_data` - a table of underlying payments table names defined in the task above.
* `preprocessing_columns` - move data from `gs://littlepay-data-extract-prod` to `gs://gtfs-data`,
  then process to keep only columns defined in external tables.
