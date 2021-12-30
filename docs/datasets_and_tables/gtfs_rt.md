# GTFS Realtime

We collect realtime data every 20 seconds for feeds listed in [agencies.yml](../warehouse/agencies.md).
This data is processed and validated daily.


## Data

| dataset | description |
| ------- | ----------- |
| `gtfs_rt` | Internal warehouse dataset for preparing GTFS RT views |
| `views.gtfs_rt_*` | User-friendly tables for analyzing GTFS RT data  |
| `views.validation_rt_*` | User-friendly tables for analyzing GTFS RT validation data |

## View Tables

Note that this data is still a work in progress, so no views have been created yet.

| Tablename | Description | Notes |
|----- | -------- | -------|
| | | |

## Internal Tables

| Tablename | Description | Notes |
| --------- | ----------- | ----- |
| `calitp_files` | Metadata on each RT feed file we sample every 20 seconds (e.g. vehicle positions) | |
| `vehicle_positions` | One row per feed individual vehicle position reported every 20 seconds | Sampling times occur in 20 second intervals, but not on specific points in time. |
| `validation_service_alerts` | Each row is the contents of an individual results file from the GTFS RT validator | |
| `validation_trip_updates` | Similar to above, but for trip updates. | |
| `validation_vehicle_positions` | Similar to above, but for vehicle positions. | |

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

Extraction of GTFS RT feeds is handled by the [gtfs-rt-archive service](../services/gtfs-rt-archive.md). For Logs, we are using google cloud logger with a user-definited metric as a sink to output to BigQuery. The metric used is 'gtfs-rt-url-errors' and it filters for logName='stdout', namespace_name="gtfs-rt", and severity="INFO". Currently all the url-errors are treated as severity="INFO".The destination is bigquery and because the table names are not changable (gtfs_rt.stdout), they were put in their own dataset (gtfs_rt_logs).

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
