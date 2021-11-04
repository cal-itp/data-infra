---
jupytext:
  cell_metadata_filter: -all
  formats: md:myst
  text_representation:
    extension: .md
    format_name: myst
    format_version: 0.13
    jupytext_version: 1.10.3
kernelspec:
  display_name: Python 3 (ipykernel)
  language: python
  name: python3
---

# Datasets

| page | description | datasets |
| ---- | ----------- | -------- |
| [GTFS Schedule](./gtfs_schedule.md) | GTFS Schedule data for the current day | `gtfs_schedule`, `gtfs_schedule_history`, `gtfs_schedule_type2` |
| [MST Payments](./mst_payments.md) | TODO | TODO |
| [Transitstacks](./transitstacks.md) | TODO | `transitstacks`, `views.transitstacks` |
| [Views](./views.md) | End-user friendly data for dashboards and metrics | E.g. `views.validation_*`, `views.gtfs_schedule_*` |

## Views
### Data

| dataset | description | examples |
| ------- | ----------- | -------- |
| `views.gtfs_agency_names` | One row per GTFS Static data feed, with `calitp_itp_id`, `calitp_url_number`, and `agency_name` | |
| `views.gtfs_schedule_service_daily` | `calendar.txt` data from GTFS Static unpacked and joined with `calendar_dates.txt` to reflect service schedules on a given day. Critically, it uses the data that was current on `service_date`. For `service_date` values in the future, uses most recent data in warehouse. | |
| `views.validation_notices` | One line per specific validation violation (e.g. each invalid phone number). See `validation_code_descriptions` for human friendly code labels, and `validation_notice_fields` for looking up what columns in `validation_notices` different codes have data for (e.g. the code `"invalid_phone_number"` sets the `fieldValue` column). | |

### Maintenance

#### DAGs overview

Views are held in the [`gtfs_views`](https://github.com/cal-itp/data-infra/tree/main/airflow/dags/gtfs_views) DAG.

## GTFS Schedule

| Dataset | Description |
| ------- | ----------- |
| gtfs_schedule | Latest warehouse data for GTFS Static feeds. See the [GTFS static reference](https://developers.google.com/transit/gtfs/reference). |
| gtfs_schedule_type2 | Tables with GTFS Static feeds across history (going back to April 15th, 2021). These are stored as type 2 slowly changing dimensions. They have `calitp_extracted_at`, and `calitp_deleted_at` fields. |
| (internal) gtfs_schedule_history | External tables with all new feed data across history. |
### Dashboards
### Maintenance
### DAGs Overview
### Common Issues
### Backfillings

## GTFS RT
## MST Payments

Currently, Payments data is hosted by Littlepay, who exposes the "Littlepay Data Model" as a set of files stored in an S3 bucket. To get a copy of the data docs, email hunter.

### Tables

| Tablename | Description | Notes |
|----- | -------- | -------|
| device_transactions | A list of every tap on the devices | * Cannot use for ridership stats because tap on / offs |
| micropayments | A list of every charge to a card | * T-2 delays because of charing rules |
| micropayments_devices_transactions | Join tables for two prior tables | |
| micropayment_adjustments | A list of amounts deducted from the `nominal_amount` to arrive at the `charge_amount` for a micropayment | A micropayment can include multiple adjustments candidates, but only one should have `applied=true`. |

### Views

The table best used for caculating ridership is `mst_ridership_materialized` table.

### Maintenance

The ETL is currently a scheduled Google Data Transfer job that transfers all files to `gcs://littlepay-data-extract-prod`

From there, tables are loaded into BigQuery as external tables in the `transaction_data` buclet.

#### DAGs Overview

The payments data is loaded and transformed in the payments_loader and payments_views dags.

The payments_loader dag has three kinds of tasks:

* ExternalTable operator tasks (e.g. `customer_funding_source`). These define the underlying data.
* `calitp_included_payments_data` - a table of underlying payments table names defined in the task above.
* `preprocessing_columns` - move data from `gs://littlepay-data-extract-prod` to `gs://gtfs-data`,
  then process to keep only columns defined in external tables.

The payments_views is made of SQL queries that transform the loaded tables above.

#### Adding new tables in payments_loader

* Copy the `customer_funding_source` task. The new task name should match the table it creates.
* Alter `destination_project_dataset_table` and `source_objects` to match the new table name.
* Edit `schema_fields` to be the columns in the new table. If you are unsure of a column type,
  specify it as "STRING".
    * Keep a `calitp_extracted_at` column at the end of the table. This column contains the execution date of the load task, and is added automatically by the `preprocess_columns` task.
* In the `calitp_included_payments_data` task,
    * add a row for this new table.
    * add a depedency in yaml header to this new table.
* In the `docs/datasets/mst_payments.md` file, add an entry into the `Tables` table describing the new data set.

#### Adding a new table to payments_views

* Ensure your task is given the same name as the table it creates.
* Be sure to include an `external_dependency` on payments_loader (see other views in payments_views).

#### Backfilling

Clear the `preprocessing_columns` task for every day you want to re-run.
These tasks do not depend on past. However, because the extracted data in the littlepay bucket
can be mutated by littlepay, so if you clear a past task, you should clear them all!


## Transitstacks

[![](https://mermaid.ink/img/eyJjb2RlIjoiZXJEaWFncmFtXG4gICAgT3JnYW5pemF0aW9uIH1vLS1veyBDb250YWN0IDogXCJyZXByZXNlbnRlZCBieVwiXG4gICAgT3JnYW5pemF0aW9uIH1vLS1veyBTZXJ2aWNlOiBcIm1hbmFnZXNcIlxuICAgIE9yZ2FuaXphdGlvbiB9by0tb3sgU2VydmljZTogXCJvcGVyYXRlc1wiXG4gICAgT3JnYW5pemF0aW9uIH1vLS1veyBDb250cmFjdDogXCJvd25zXCJcbiAgICBPcmdhbml6YXRpb24gfW8tLW97IENvbnRyYWN0OiBcImhvbGRzXCJcbiAgICBPcmdhbml6YXRpb24gfW8tLW97IFByb2R1Y3Q6IFwic2VsbHNcIlxuICAgIE9yZ2FuaXphdGlvbiB9by0tb3sgR3Rmc0RhdGFzZXQ6IFwiY29uc3VtZXNcIlxuICAgIE9yZ2FuaXphdGlvbiB9by0tb3sgR3Rmc0RhdGFzZXQ6IFwicHJvZHVjZXNcIlxuXG4gICAgU2VydmljZSB9by0tb3sgR3Rmc0RhdGFzZXQ6IFwicmVmbGVjdGVkIGJ5XCJcblxuICAgIE9yZ2FuaXphdGlvblN0YWNrQ29tcG9uZW50IH1vLi5veyBPcmdhbml6YXRpb246IFwiYXNzb2NpYXRlc1wiXG4gICAgT3JnYW5pemF0aW9uU3RhY2tDb21wb25lbnQgfW8uLm97IFByb2R1Y3Q6IFwiYXNzb2NpYXRlc1wiXG4gICAgT3JnYW5pemF0aW9uU3RhY2tDb21wb25lbnQgfW8uLm97IENvbXBvbmVudDogXCJhc3NvY2lhdGVzXCJcbiAgICBPcmdhbml6YXRpb25TdGFja0NvbXBvbmVudCB9by4ub3sgQ29udHJhY3Q6IFwiYXNzb2NpYXRlc1wiXG5cbiAgICBPcmdhbml6YXRpb25TdGFja0NvbXBvbmVudFJlbGF0aW9uc2hpcCB9by4ub3sgT3JnYW5pemF0aW9uU3RhY2tDb21wb25lbnQ6IGNvbXBvbmVudEFcbiAgICBPcmdhbml6YXRpb25TdGFja0NvbXBvbmVudFJlbGF0aW9uc2hpcCB9by4ub3sgT3JnYW5pemF0aW9uU3RhY2tDb21wb25lbnQ6IGNvbXBvbmVudEIiLCJtZXJtYWlkIjp7InRoZW1lIjoiZGVmYXVsdCJ9LCJ1cGRhdGVFZGl0b3IiOmZhbHNlLCJhdXRvU3luYyI6dHJ1ZSwidXBkYXRlRGlhZ3JhbSI6dHJ1ZX0)](https://mermaid-js.github.io/mermaid-live-editor/edit/#eyJjb2RlIjoiZXJEaWFncmFtXG4gICAgT3JnYW5pemF0aW9uIH1vLS1veyBDb250YWN0IDogXCJyZXByZXNlbnRlZCBieVwiXG4gICAgT3JnYW5pemF0aW9uIH1vLS1veyBTZXJ2aWNlOiBcIm1hbmFnZXNcIlxuICAgIE9yZ2FuaXphdGlvbiB9by0tb3sgU2VydmljZTogXCJvcGVyYXRlc1wiXG4gICAgT3JnYW5pemF0aW9uIH1vLS1veyBDb250cmFjdDogXCJvd25zXCJcbiAgICBPcmdhbml6YXRpb24gfW8tLW97IENvbnRyYWN0OiBcImhvbGRzXCJcbiAgICBPcmdhbml6YXRpb24gfW8tLW97IFByb2R1Y3Q6IFwic2VsbHNcIlxuICAgIE9yZ2FuaXphdGlvbiB9by0tb3sgR3Rmc0RhdGFzZXQ6IFwiY29uc3VtZXNcIlxuICAgIE9yZ2FuaXphdGlvbiB9by0tb3sgR3Rmc0RhdGFzZXQ6IFwicHJvZHVjZXNcIlxuXG4gICAgU2VydmljZSB9by0tb3sgR3Rmc0RhdGFzZXQ6IFwicmVmbGVjdGVkIGJ5XCJcblxuICAgIE9yZ2FuaXphdGlvblN0YWNrQ29tcG9uZW50IH1vLi5veyBPcmdhbml6YXRpb246IFwiYXNzb2NpYXRlc1wiXG4gICAgT3JnYW5pemF0aW9uU3RhY2tDb21wb25lbnQgfW8uLm97IFByb2R1Y3Q6IFwiYXNzb2NpYXRlc1wiXG4gICAgT3JnYW5pemF0aW9uU3RhY2tDb21wb25lbnQgfW8uLm97IENvbXBvbmVudDogXCJhc3NvY2lhdGVzXCJcbiAgICBPcmdhbml6YXRpb25TdGFja0NvbXBvbmVudCB9by4ub3sgQ29udHJhY3Q6IFwiYXNzb2NpYXRlc1wiXG5cbiAgICBPcmdhbml6YXRpb25TdGFja0NvbXBvbmVudFJlbGF0aW9uc2hpcCB9by4ub3sgT3JnYW5pemF0aW9uU3RhY2tDb21wb25lbnQ6IGNvbXBvbmVudEFcbiAgICBPcmdhbml6YXRpb25TdGFja0NvbXBvbmVudFJlbGF0aW9uc2hpcCB9by4ub3sgT3JnYW5pemF0aW9uU3RhY2tDb21wb25lbnQ6IGNvbXBvbmVudEIiLCJtZXJtYWlkIjoie1xuICBcInRoZW1lXCI6IFwiZGVmYXVsdFwiXG59IiwidXBkYXRlRWRpdG9yIjpmYWxzZSwiYXV0b1N5bmMiOnRydWUsInVwZGF0ZURpYWdyYW0iOnRydWV9)


### Dashboards

### Maintenance

#### DAGs overview
