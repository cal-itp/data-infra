(gtfs-realtime)=
# GTFS Realtime

We collect realtime data every 20 seconds for feeds listed in [agencies.yml](../airflow/agencies.md).
This data is processed and validated daily.


## Data

| dataset | description |
| ------- | ----------- |
| [`views.gtfs_rt_*`](gtfs-rt-views) | User-friendly tables for analyzing GTFS RT data  |
| [`views.validation_rt_*`](validation-rt-views) | User-friendly tables for analyzing GTFS RT validation data |
| `gtfs_rt` | Internal warehouse dataset for preparing GTFS RT views |
| `gtfs_rt_logs` | Internal warehouse dataset for GTFS RT extraction logs |

## View Tables
(gtfs-rt-views)=
### GTFS-Realtime Views
|Table                                                    |Description|Link                                                                                                                                    |
|---------------------------------------------------------|-----------|----------------------------------------------------------------------------------------------------------------------------------------|
|gtfs_rt_fact_daily_feeds                                 |           |<a href="https://dbt-docs.calitp.org/#!/model/model.calitp_warehouse.gtfs_rt_fact_daily_feeds">link</a>                                 |
|gtfs_rt_fact_daily_validation_errors                     |           |<a href="https://dbt-docs.calitp.org/#!/model/model.calitp_warehouse.gtfs_rt_fact_daily_validation_errors">link</a>                     |
|gtfs_rt_fact_extraction_errors                           |     Each feed per timepoint that failed to download. Records go back to `2021-12-13`.      |<a href="https://dbt-docs.calitp.org/#!/model/model.calitp_warehouse.gtfs_rt_fact_extraction_errors">link</a>                           |
|gtfs_rt_fact_files                                       |           |<a href="https://dbt-docs.calitp.org/#!/model/model.calitp_warehouse.gtfs_rt_fact_files">link</a>                                       |
|gtfs_rt_fact_files_wide_hourly                           |           |<a href="https://dbt-docs.calitp.org/#!/model/model.calitp_warehouse.gtfs_rt_fact_files_wide_hourly">link</a>                           |
|gtfs_rt_validation_code_descriptions                     |           |<a href="https://dbt-docs.calitp.org/#!/model/model.calitp_warehouse.gtfs_rt_validation_code_descriptions">link</a>                     |

(validation-rt-views)=
### Validation-Realtime Views
|Table                                                    |Description|Link                                                                                                                                    |
|---------------------------------------------------------|-----------|----------------------------------------------------------------------------------------------------------------------------------------|
|gtfs_rt_validation_code_descriptions                     |           |<a href="https://dbt-docs.calitp.org/#!/model/model.calitp_warehouse.gtfs_rt_validation_code_descriptions">link</a>                     |

## Internal Tables

| Tablename | Description | Notes |
| --------- | ----------- | ----- |
| `calitp_files` | Metadata on each RT feed file we sample every 20 seconds (e.g. vehicle positions) | |
| `vehicle_positions` | One row per feed individual vehicle position reported every 20 seconds | Sampling times occur in 20 second intervals, but not on specific points in time. |
| `validation_service_alerts` | Each row is the contents of an individual results file from the GTFS RT validator | |
| `validation_trip_updates` | Similar to above, but for trip updates. | |
| `validation_vehicle_positions` | Similar to above, but for vehicle positions. | |
