# MST Payments

Currently, Payments data is hosted by Littlepay, who exposes the "Littlepay Data Model" as a set of files stored in an S3 bucket. To get a copy of the data docs, email hunter.

## Tables

| Tablename | Description | Notes |
|----- | -------- | -------|
| device_transactions | A list of every tap on the devices | * Cannot use for ridership stats because tap on / offs |
| micropayments | A list of every charge to a card | * T-2 delays because of charing rules |
| micropayments_devices_transactions | Join tables for two prior tables | |

## Views

The table best used for caculating ridership is `mst_ridership_materialized` table.

## Maintenance


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
* In the `calitp_included_payments_data` task,
  - add a row for this new table.
  - add a depedency in yaml header to this new table.

### Adding a new table to payments_views

* Ensure your task is given the same name as the table it creates.
* Be sure to include an `external_dependency` on payments_loader (see other views in payments_views).

### Backfilling

Clear the `preprocessing_columns` task for every day you want to re-run.
These tasks do not depend on past. However, because the extracted data in the littlepay bucket
can be mutated by littlepay, so if you clear a past task, you should clear them all!
