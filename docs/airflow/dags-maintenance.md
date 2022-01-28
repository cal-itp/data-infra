# DAGs maintenance
Use this page to find information on maintenance of the DAGs that support our data pipelines.

1. [GTFS Schedule DAGs](gtfs-schedule-dags)
1. [GTFS Realtime DAGs](gtfs-realtime-dags)
1. [MST Payments DAGs](mst-payments-dags)
1. [Transit Database DAGs](transit-database-dags)
1. [Views DAGs](views-dags)

(gtfs-schedule-dags)=
## GTFS Schedule - DAGs Maintenance

### DAGs overview

### common issues

### backfilling

(gtfs-realtime-dags)=
## GTFS Realtime - DAGs Maintenance

### DAGs Overview

Currently, 3 DAGs are used with GTFS RT data:

* `rt_loader_files`: Populates a table called `gtfs_rt.calitp_files` that has one row per
    sample of GTFS RT data. For example, a vehicle positions file downloaded at a specific point in time.
* `rt_loader`: handles the rectangling and loading of GTFS RT and validation data.
* `rt_views`: exposes user-friendly views for analysis.

Internal data should live in the `gtfs_rt` dataset on bigquery, while those that are
broadly useful across the org should live in `views`.

### Extraction

Extraction of GTFS RT feeds is handled by the [gtfs-rt-archive service](../services/gtfs-rt-archive.md). Within the service, `agencies.yml` is read into separate threads and each RT feed is uploaded to a GCPBucketWriter via a post request. This data is stored in a kubernetes cluster `data-infra-apps`.

### Logging

Within the gtfs-rt-archive service, A logger channel is set up with the `logging` facility for Python. If an error is raised within the service, the log messages are also uploaded and stored in the cluster `data-infra-apps`. Within this logger object some of the errors we are currently logging and their associated error levels:

* missing feeds (Warning)
* missing itp_id (Warning)
* event dropped (Warning)
* ticker (Debug)
* error fetching URL (Info)

Google cloud automatically creates specific buckets called 'logging buckets' when a kubernetes cluster is stood up, these are called `_Default` and `_Required`. Cloud Logging provides these two predefined sinks for each Cloud Project. All logs that are generated in a resource are automatically processed through those two sinks and then are stored either in the `_Required` or `_Default` Buckets. `_Required` has retention for 400 days and appears to have mostly audit log functionality for data compliance. We are mostly using _Default which has a retention of 30 days to log all of our cloud services. `_Default` gets updated from the kubernetes cluster in hourly batches. We created a log sink called `rt-extract-to-bigquery` that filters the logs within `_Default` for the namespace `resource.labels.namespace_name="gtfs-rt"`. To reliably route logs, the log router stores the logs temporarily, which buffers against temporary disruptions on any sink. According to this documentation, the log logging frequency between Cloud Logging and Bigquery is [near real-time](https://cloud.google.com/logging/docs/export/using_exported_logs#bigquery-frequency).

Within The BigQuery table, the error messages are stored within the stdout table. The table names are generated automatically through the cloud router and cannot be renamed. The stout table is a partitioned table that does not have any limits on storage size currently. See [Google Cloud Log Router docs](https://cloud.google.com/logging/docs/routing/overview) for more information. The raw logs may be browsed in the [Logs Explorer](https://console.cloud.google.com/logs/query?project=cal-itp-data-infra).

### Validation

Validation of GTFS RT uses the [gtfs-rt-validator-api](https://github.com/cal-itp/gtfs-rt-validator-api).
This repo publishes a docker image on every release, so that it can used from a KubernetesPodOperator.
It allows for fetching GTFS RT and schedule data from our cloud storage, validating, and putting the results
back into cloud storage.

Note that the validation process requires two pieces per feed:

* a zipped GTFS Schedule
* realtime feed data (e.g. vehicle positions, trip updates, service alerts)

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

### Adding new tables in payments_loader

* Copy the `customer_funding_source` task. The new task name should match the table it creates.
* Alter `destination_project_dataset_table` and `source_objects` to match the new table name.
* Edit `schema_fields` to be the columns in the new table. If you are unsure of a column type,
  specify it as "STRING".
    * Keep a `calitp_extracted_at` column at the end of the table. This column contains the execution date of the load task, and is added automatically by the `preprocess_columns` task.
* In the `calitp_included_payments_data` task,
    * add a row for this new table.
    * add a depedency in yaml header to this new table.
* In the `docs/datasets/mst_payments.md` file, add an entry into the `Tables` table describing the new data set.

### Adding a new table to payments_views

* Ensure your task is given the same name as the table it creates.
* Be sure to include an `external_dependency` on payments_loader (see other views in payments_views).

### Backfilling

Clear the `preprocessing_columns` task for every day you want to re-run.
These tasks do not depend on past. However, because the extracted data in the littlepay bucket
can be mutated by littlepay, so if you clear a past task, you should clear them all!

(transit-database-dags)=
## Transit Database - DAGs Maintenance

### DAGs Overview

(views-dags)=
## Views - DAGs Maintenance

### DAGs overview

Views are held in the [`gtfs_views`](https://github.com/cal-itp/data-infra/tree/main/airflow/dags/gtfs_views) DAG.
