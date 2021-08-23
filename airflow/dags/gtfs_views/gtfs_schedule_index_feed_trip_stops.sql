---
operator: operators.SqlToWarehouseOperator
dst_table_name: "views.gtfs_schedule_index_feed_trip_stops"
dependencies:
  - gtfs_schedule_dim_feeds
  - gtfs_schedule_dim_trips
  - gtfs_schedule_dim_routes
  - gtfs_schedule_dim_stop_times
  - gtfs_schedule_dim_stops
---

WITH

feed_routes AS (

{{
    scd_join(
        "views.gtfs_schedule_dim_feeds",
        "views.gtfs_schedule_dim_routes",
        using_cols = ("calitp_itp_id", "calitp_url_number"),
        sel_left_cols = ["feed_key", "calitp_itp_id", "calitp_url_number"],
        sel_right_cols = ["route_key", "route_id"],
    )
}}

),

feed_route_trips AS (

{{
    scd_join(
        "feed_routes",
        "views.gtfs_schedule_dim_trips",
        using_cols = ("calitp_itp_id", "calitp_url_number", "route_id"),
        sel_right_cols = ["trip_key", "trip_id"],
    )

}}

),

feed_trip_stop_times AS (

{{
    scd_join(
        "feed_route_trips",
        "views.gtfs_schedule_dim_stop_times",
        using_cols = ("calitp_itp_id", "calitp_url_number", "trip_id"),
        sel_right_cols = ["stop_time_key", "stop_id"],
    )

}}

),

feed_trip_stops AS (

{{
    scd_join(
        "feed_trip_stop_times",
        "views.gtfs_schedule_dim_stops",
        using_cols = ("calitp_itp_id", "calitp_url_number", "stop_id"),
        sel_right_cols = ["stop_key"],
    )

}}

)

SELECT
    * EXCEPT (calitp_itp_id, calitp_url_number, route_id, trip_id, stop_id)
FROM feed_trip_stops
