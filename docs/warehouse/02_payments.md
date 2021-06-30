# Payments Data

Currently, Payments data is hosted by Littlepay, who exposes the "Littlepay Data Model" as a set of files stored in an S3 bucket. To get a copy of the data docs, email hunter.

## ELT

The ETL is currently a scheduled Google Data Transfer job that transfers all files to `gcs://littlepay-data-extract-prod`

From there, tables are loaded into BigQuery as external tables in the `transaction_data` buclet.

Finally, there is a operator `payments_update` that runs nightly to refresh the `mst_ridership_materialized` table.
## Tables

| Tablename | Description | Notes |
|----- | -------- | -------|
| device_transactions | A list of every tap on the devices | * Cannot use for ridership stats because tap on / offs |
| micropayments | A list of every charge to a card | * T-2 delays because of charing rules |
| micropayments_devices_transactions | Join tables for two prior tables | |

## Views

The table best used for caculating ridership is `mst_ridership_materialized` table.
