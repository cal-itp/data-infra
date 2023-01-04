# DAGs Maintenance
Use this page to find information on maintenance of the DAGs that support our data pipelines.

1. [GTFS Schedule DAGs](gtfs-schedule-dags)
1. [GTFS Realtime DAGs](gtfs-realtime-dags)
1. [MST Payments DAGs](mst-payments-dags)
1. [Transit Database DAGs](transit-database-dags)
1. [Views DAGs](views-dags)

(gtfs-schedule-dags)=
## GTFS Schedule - DAGs Maintenance

### DAGs Overview

### Common Issues

### Backfilling

(gtfs-realtime-dags)=
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

(mst-payments-dags)=
## MST Payments - DAGs Maintenance

The ETL is currently a scheduled Google Data Transfer job that transfers all files to `gcs://littlepay-data-extract-prod`

From there, tables are loaded into BigQuery as external tables in the `transaction_data` buclet.

### DAGs Overview

The payments data is loaded and transformed in the payments_loader and payments_views dags.

The payments_loader dag has three kinds of tasks:

* ExternalTable operator tasks (e.g. `customer_funding_source`). These define the underlying data.
* `calitp_included_payments_data` - a table of underlying payments table names defined in the task above.
* `preprocessing_columns` - move data from `gs://littlepay-data-extract-prod` to `gs://gtfs-data`,
  then process to keep only columns defined in external tables.

The payments_views is made of SQL queries that transform the loaded tables above.

### Adding New Tables in payments_loader

* Copy the `customer_funding_source` task. The new task name should match the table it creates.
* Alter `destination_project_dataset_table` and `source_objects` to match the new table name.
* Edit `schema_fields` to be the columns in the new table. If you are unsure of a column type,
  specify it as "STRING".
    * Keep a `calitp_extracted_at` column at the end of the table. This column contains the execution date of the load task, and is added automatically by the `preprocess_columns` task.
* In the `calitp_included_payments_data` task,
    * add a row for this new table.
    * add a depedency in yaml header to this new table.
* In the `docs/datasets/mst_payments.md` file, add an entry into the `Tables` table describing the new data set.

### Adding a New Table to payments_views

* Ensure your task is given the same name as the table it creates.
* Be sure to include an `external_dependency` on payments_loader (see other views in payments_views).

### Backfilling

(transit-database-dags)=
## Transit Database - DAGs Maintenance

### DAGs Overview

(views-dags)=
## Views - DAGs Maintenance

### DAGs Overview
