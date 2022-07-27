# GTFS Schedule
This section contains information for `source` and `staging` tables only. For documentation on GTFS Schedule `views`, [visit this link](view-models).

## Warehouse Schemas

### Source

| dataset name | description |
| ------- | ----------- |
| `gtfs_schedule_type2` | Tables with GTFS-Static feeds across history (going back to April 15 2021). These are stored as type 2 slowly changing dimensions. They have `calitp_extracted_at` and `calitp_deleted_at` fields. |
| `gtfs_schedule_history` | Data in the `gtfs_schedule_history` dataset in BigQuery |
| (Reference) [GTFS-Schedule Data Standard](https://developers.google.com/transit/gtfs/) | A reference to the GTFS-Schedule data standard. |

### Staging

| dataset name | description |
| ------- | ----------- |
| `gtfs_schedule_latest_only` | Latest warehouse data for GTFS-Schedule feeds. |
| `gtfs_views_staging` | A staging schema for `gtfs_views`. |

## How to view the documentation

Documentation for our `GTFS Schedule` tables can be found in our `dbt` documentation: [dbt-docs.calitp.org](https://dbt-docs.calitp.org/#!/overview)

In the documentation, you can navigate from either the `Database` perspective (table-level) or the `Project` perspective (as the files are configured in the repository).

### The `Database` Perspective
This allows you to view the dbt project as it exists in the warehouse.

To examine the documentation for our `GTFS Schedule` tables from the `Database` perspective:

1. Once at the [dbt docs homepage](https://dbt-docs.calitp.org/#!/overview), make sure that the `Database` tab is selected in the left-side panel.
1. In the same left-side panel, under the `Tables and Views` heading click on `cal-itp-data-infra`, which will expand.
1. Within that list, select tables from the below to view their documentation:
    * Sources:
        * `gtfs_schedule_history`
        * `gtfs_schedule_type2`
    * Staging tables:
        * `gtfs_schedule`
        * `gtfs_views_staging`

### The `Project` Perspective
This allows you to view the warehouse project as it exists in the repository.

To examine the documentation for our `GTFS Schedule` tables from the `Project` perspective:

* Once at the [dbt docs homepage](https://dbt-docs.calitp.org/#!/overview), make sure that the `Project` tab is selected in the left-side panel.
    * To examine our source tables:
        1. In the same left-side panel, find the `Sources` heading
        1. From here, select the `GTFS Schedule` source that you would like to view, from any of the below:
            * `gtfs_schedule_history`
            * `gtfs_type2`
    * To examine our staging tables:
        1. In the same left-side panel, under the `Projects` heading click on `calitp_warehouse`, which will expand.
        1. Within that list, select `models`
        1. From here, the relevent file directories are below. Select any of the tables within them to view their documentation.
            * `gtfs_schedule_latest_only`
            * `gtfs_views_staging`

:::{admonition} (Tables Reference) GTFS-Schedule Data Standard
:class: tip
For background on the tables used to make up the GTFS-Schedule standard, see this [GTFS-Schedule data standard reference](https://developers.google.com/transit/gtfs/).
:::
