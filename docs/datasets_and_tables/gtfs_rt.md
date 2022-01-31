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

## DAGs Maintenance

You can find further information on DAGs maintenance for GTFS Realtime data [on this page](gtfs-realtime-dags).
