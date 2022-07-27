(view-models)=
# Views

End-user friendly data for dashboards and metrics

Documentation for our `views` tables can be found in our `dbt` documentation: [dbt-docs.calitp.org](https://dbt-docs.calitp.org/#!/overview)

## How to view the documentation:

In the documentation, you can navigate from either the `Database` perspective (table-level) or the `Project` perspective (as the files are configured in the repository).

### The `Database` Perspective
This allows you to view the dbt project as it exists in the warehouse.

To examine the documentation for our `views` tables from the `Database` perspective:

1. Once at the [dbt docs homepage](https://dbt-docs.calitp.org/#!/overview), make sure that the `Database` tab is selected in the left-side panel.
1. In the same left-side panel, under the `Tables and Views` heading click on `cal-itp-data-infra`, which will turn into a drop-down.
1. Within that dropdown, select `views`
1. From here, the relevent tables are within this dropdown. Select any of the tables within them to view the documentation.

### The `Project` Perspective
This allows you to view the warehouse project as it exists in the repository.

To examine the documentation for our `views` tables from the `Project` perspective:

1. Once at the [dbt docs homepage](https://dbt-docs.calitp.org/#!/overview), make sure that the `Project` tab is selected in the left-side panel.
1. In the same left-side panel, under the `Projects` heading click on `calitp_warehouse`, which will turn into a drop-down.
1. Within that dropdown, select `models`
1. From here, the relevent file directories are below. Select any of the tables within them to view the documentation.
    * `gtfs_views`
    * `rt_views`
    * `payments_views`
