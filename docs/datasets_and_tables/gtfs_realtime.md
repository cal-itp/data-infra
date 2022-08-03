(gtfs-realtime)=
# GTFS Realtime

We collect realtime data every 20 seconds for feeds listed in [agencies.yml](../airflow/agencies.md).
This data is processed and validated daily.

## How to view the `GTFS Realtime` documentation

Visit the [dbt Cal-ITP warehouse documentation](https://dbt-docs.calitp.org/#!/overview). For help navgating the documentation, visit [Navigating the dbt Docs](navigating-dbt-docs).

## Warehouse Schemas

### Source
| dataset name | description |
| ------- | ----------- |
| `external_gtfs_rt` | Hive-partitioned external tables reading GTFS RT data and validation errors from GCS. |
| `gtfs_rt_logs` | Data in the gtfs_rt_logs dataset in BigQuery, from logs sink. |
| `gtfs_rt` | Data in the gtfs_rt dataset in BigQuery, generally produced by the rt_loader and rt_loader_files Airflow DAGs. |

### Staging
| dataset name | description |
| ------- | ----------- |
| `staging` | tables with a prefix `staging.stg_rt__*` |

### Internal Tables

| Tablename | Description | Notes |
| --------- | ----------- | ----- |
| `calitp_files` | Metadata on each RT feed file we sample every 20 seconds (e.g. vehicle positions) | |
| `vehicle_positions` | One row per feed individual vehicle position reported every 20 seconds | Sampling times occur in 20 second intervals, but not on specific points in time. |
| `validation_service_alerts` | Each row is the contents of an individual results file from the GTFS RT validator | |
| `validation_trip_updates` | Similar to above, but for trip updates. | |
| `validation_vehicle_positions` | Similar to above, but for vehicle positions. | |

### See Also
The [GTFS-Realtime Data Standard](https://developers.google.com/transit/gtfs-realtime/).

## dbt Project Directories ([More information on the project-perspective](navigating-dbt-docs))

### Source tables
| Directory name |
| ------- |
| `gtfs_rt_external_tables` |
| `gtfs_rt_logs` |
| `gtfs_rt_raw` |

### Staging tables
| Directory name |
| ------- |
| `staging/rt/` |

:::{admonition} See Also: `views` documentation
:class: tip
This section contains information for `source` and `staging` tables only. For documentation on GTFS Realtime `views`, [visit this link](view-models).
:::
