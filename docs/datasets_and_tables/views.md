(view-models)=
# Views

End-user-friendly data for dashboards and metrics

## How to view the `views` documentation

In the [Cal-ITP warehouse documentation](https://dbt-docs.calitp.org/#!/overview), you can navigate from either the `Database` perspective (table-level) or the `Project` perspective (as the files are configured in the repository).

### The `Database` Perspective
This allows you to view the dbt project as it exists in the warehouse.

To examine the documentation for our `views` tables from the `Database` perspective:

1. Once at the [dbt docs homepage](https://dbt-docs.calitp.org/#!/overview), make sure that the `Database` tab is selected in the left-side panel.
1. In the same left-side panel, under the `Tables and Views` heading click on `cal-itp-data-infra`, which will expand.
1. Within that dropdown, select:
  * `Views` tables
    * `views`
    * `mart_transit_database`
  * `Staging` tables:
    * GTFS Views: `gtfs_views_staging`
1. From here, the relevent tables are listed. Select any of the tables within to view the documentation.

### The `Project` Perspective
This allows you to view the warehouse project as it exists in the repository.

To examine the documentation for our `views` tables from the `Project` perspective:

1. Once at the [dbt docs homepage](https://dbt-docs.calitp.org/#!/overview), make sure that the `Project` tab is selected in the left-side panel.
1. In the same left-side panel, under the `Projects` heading click on `calitp_warehouse`, which will expand.
1. Within that dropdown, select `models`
1. From here, the relevent file directories are included in the list. Select any of the tables within them to view their documentation.
  * `Views` tables
    * `gtfs_views`
    * `rt_views`
    * `payments_views`
    * `mart`
  * `Staging` tables:
    * GTFS Views: `gtfs_views_staging`
