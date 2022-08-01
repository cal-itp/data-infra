(gtfs-realtime)=
# GTFS Realtime

We collect realtime data every 20 seconds for feeds listed in [agencies.yml](../airflow/agencies.md).
This data is processed and validated daily.

## How to view the `GTFS Realtime` documentation

In the [Cal-ITP warehouse documentation](https://dbt-docs.calitp.org/#!/overview), you can navigate from either the `Database` perspective (table-level) or the `Project` perspective (as the files are configured in the repository).

### The `Database` Perspective
This allows you to view the dbt project as it exists in the warehouse.

To examine the documentation for our `GTFS Realtime` tables from the `Database` perspective:

1. Once at the [dbt docs homepage](https://dbt-docs.calitp.org/#!/overview), make sure that the `Database` tab is selected in the left-side panel.
1. In the same left-side panel, under the `Tables and Views` heading click on `cal-itp-data-infra`, which will expand.
1. Within that list, select tables from the below to view their documentation:
    * Sources:
        * `external_gtfs_rt`
        * `gtfs_rt_logs`
        * `gtfs_rt`
    * Staging tables:
        * `staging`
            * tables with a prefix `staging.stg_rt__*`

### The `Project` Perspective
This allows you to view the warehouse project as it exists in the repository.

To examine the documentation for our `GTFS Realtime` tables from the `Project` perspective:

* Once at the [dbt docs homepage](https://dbt-docs.calitp.org/#!/overview), make sure that the `Project` tab is selected in the left-side panel.
    * To examine our source tables:
        1. In the same left-side panel, find the `Sources` heading
        1. From here, select the `GTFS Realtime` source that you would like to view, from any of the below:
            * `gtfs_rt_external_tables`
            * `gtfs_rt_logs`
            * `gtfs_rt_raw`
    * To examine our staging tables:
        1. In the same left-side panel, under the `Projects` heading click on `calitp_warehouse`, which will expand.
        1. Within that list, select `models`
        1. Then select `staging`
        1. Within that list you will find the `rt` directory
            * From here, select any of the tables within to view their documentation.

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

:::{admonition} See Also: `views` documentation
:class: tip
This section contains information for `source` and `staging` tables only. For documentation on GTFS Realtime `views`, [visit this link](view-models).
:::
