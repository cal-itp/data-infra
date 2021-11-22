# GTFS Realtime

Currently, Payments data is hosted by Littlepay, who exposes the "Littlepay Data Model" as a set of files stored in an S3 bucket. To get a copy of the data docs, email hunter.

## Data

| dataset | description |
| ------- | ----------- |
| `gtfs_rt` | Internal warehouse dataset for preparing GTFS RT views |
| `views.gtfs_rt_*` | User-friendly tables for analyzing GTFS RT data  |
| `views.validation_rt_*` | User-friendly tables for analyzing GTFS RT validation data |

## View Tables

| Tablename | Description | Notes |
|----- | -------- | -------|
| | | |

## Maintenance

### DAGs Overview

Currently, 3 DAGs are used with GTFS RT data:

* `rt_loader_files`: Populates a table called `gtfs_rt.calitp_files` that has one row per
    sample of GTFS RT data. For example, a vehicle positions file downloaded at a specific point in time.
* `rt_loader`: handles the rectangling and loading of GTFS RT and validation data.
* `rt_views`: exposes user-friendly views for analysis.

Internal data should live in the `gtfs_rt` dataset on bigquery, while those that are
broadly useful across the org should live in `views`.

### Extraction

Extraction of GTFS RT feeds is handled by the [gtfs-rt-archive service](../sevices/gtfs-rt-archive.md).

### Validation

Validation of GTFS RT uses the [gtfs-rt-validator-api](https://github.com/cal-itp/gtfs-rt-validator-api).
This repo publishes a docker image on every release, so that it can used from a KubernetesPodOperator.

### Backfilling

This DAG does not have any tasks that `depends_on_past`, so you should be able to
clear and re-run tasks as needed.
