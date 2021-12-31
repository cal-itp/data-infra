# GTFS Realtime

We collect realtime data every 20 seconds for feeds listed in [agencies.yml](../warehouse/agencies.md).
This data is processed and validated daily.


## Data

| dataset | description |
| ------- | ----------- |
| `gtfs_rt` | Internal warehouse dataset for preparing GTFS RT views |
| `gtfs_rt_logs` | Internal warehouse dataset for GTFS RT extraction logs |
| `views.gtfs_rt_*` | User-friendly tables for analyzing GTFS RT data  |
| `views.validation_rt_*` | User-friendly tables for analyzing GTFS RT validation data |

## View Tables

Note that this data is still a work in progress, so many tables are still internal.

| Tablename | Description | Notes |
|----- | -------- | -------|
| `gtfs_rt_extraction_errors` | Each feed per timepoint that failed to download. | Records go back to `2021-12-13`. |

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

Extraction of GTFS RT feeds is handled by the [gtfs-rt-archive service](../services/gtfs-rt-archive.md).

### Logging

All GTFS RT feed logs are loaded to Bigquery via a [Google Logger Router called `rt-extract-to-bigquery`](https://console.cloud.google.com/logs/router?project=cal-itp-data-infra). Note that this data is saved to its own dataset (`gtfs_rt_logs`), since routers do not allow table names to be customized.

See [Google Cloud Log Router docs](https://cloud.google.com/logging/docs/routing/overview) for more information.
The raw logs may be browsed in the [Logs Explorer](https://console.cloud.google.com/logs/query?project=cal-itp-data-infra).

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
