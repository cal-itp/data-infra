(warehouse-starter-kit-page)=
# Warehouse: Where to Begin
[There is a large selection of data available in the warehouse.](https://console.cloud.google.com/bigquery?project=cal-itp-data-infra&ws=!1m0) Consider this page a short guide to the most commonly used tables in our analyses.

* [Important Links](#links)
* [Trips](#trips)
* [Shapes](#shapes)
* [Daily](#daily)
* [Other](#other)

## Important Links
* [DBT Docs Cal-ITP](https://dbt-docs.calitp.org/#!/overview) - information on all the tables in the warehouse.
* [Example notebook](https://github.com/cal-itp/data-analyses/blob/main/starter_kit/gtfs_utils_v2_examples.ipynb)
 using functions in `shared_utils.gtfs_utils_v2` that query some of the tables below.

## Trips
On a given day:
* [fct_daily_scheduled_trips](https://dbt-docs.calitp.org/#!/model/model.calitp_warehouse.fct_daily_scheduled_trips)
    * Use `gtfs_utils_v2.get_trips()`.
    * Answer how many trips is an operator scheduled to run? How many trips did a particular route make?

* [fct_observed_trips](https://dbt-docs.calitp.org/#!/model/model.calitp_warehouse.fct_observed_trips)
    * Realtime observations of trips combined with scheduled data to get a full picture of what occurred.
    * Find a trip's start time, where it went, and which route it is associated with.

## Shapes
* [fct_daily_scheduled_shapes](https://dbt-docs.calitp.org/#!/model/model.calitp_warehouse.fct_daily_scheduled_shapes)
    * Use `gtfs_utils_v2.get_shapes()`.
    * Contains `point` geometry, so you can see the length and location of a route for all the routes an operator can run on a given date.
    * Find out how many trips did an operator make for a particular route.
    * Each shape has its own `shape_id` and `array_key`.
    * An express version and the regular version of a route are considered two different shapes.

## Daily
For a given day:
* [fct_daily_scheduled_stops](https://dbt-docs.calitp.org/#!/model/model.calitp_warehouse.fct_daily_scheduled_stops)
    * Use `gtfs_utils_v2.get_stops()`.
    * Contains `point` geometry.
    * How many stops did an operator make? Where did they stop?
    * How many stops did a particular transit type (streetcar, rail, ferry, etc)?
    * Detailed information such as how passengers embark/disembark (ex: on a stop/at a station) onto a vehicle and whether or not there is wheelchair boarding.

* [fct_daily_schedule_feeds](https://dbt-docs.calitp.org/#!/model/model.calitp_warehouse.fct_daily_schedule_feeds)
    * Use `gtfs_utils_v2.schedule_daily_feed_to_organization()`.
    * Get information on an operator's schedule.
    * How many different schedule types (schedule, vehicle positions, trip updates, and/or service alerts) does an operator produce?
    * Is the URL to an operator's GTFS feed stable or not?

### Other
* [dim_annual_database_agency_information](https://dbt-docs.calitp.org/#!/model/model.calitp_warehouse.dim_annual_database_agency_information) TRANSIT_DATABASE
    * Data via the National Transit Database.
    * Information from 2018-2021 are available.
    * Includes information such as reporter type, organization type, website, and address.
    * Not every operator is required to report their data to the NTD, so this could be an incomplete dataset.

* [fct_daily_organization_combined_guideline_checks](https://dbt-docs.calitp.org/#!/model/model.calitp_warehouse.fct_daily_organization_combined_guideline_checks) GTFS_QUALITY
    * Understand how well GTFS data conforms to [California's Transit Data Guidelines](https://dot.ca.gov/cal-itp/california-transit-data-guidelines).
    * Each operator has 14 rows. Each row details how well an operator's GTFS data conforms to a certain guideline (availability on website, accurate accessibility data, etc).
