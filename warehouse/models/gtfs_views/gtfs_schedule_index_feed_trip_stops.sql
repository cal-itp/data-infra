{{ config(materialized='table') }}

WITH gtfs_schedule_dim_feeds AS (
    SELECT *
    FROM {{ ref('gtfs_schedule_dim_feeds') }}
),
gtfs_schedule_dim_trips AS (
    SELECT *
    FROM {{ ref('gtfs_schedule_dim_trips') }}
),
gtfs_schedule_dim_routes AS (
    SELECT *
    FROM {{ ref('gtfs_schedule_dim_routes') }}
),
gtfs_schedule_dim_stop_times AS (
    SELECT *
    FROM {{ ref('gtfs_schedule_dim_stop_times') }}
),
gtfs_schedule_dim_stops AS (
    SELECT *
    FROM {{ ref('gtfs_schedule_dim_stops') }}
),
feed_routes AS (

{{
    scd_join(
        tbl_a = "gtfs_schedule_dim_feeds",
        tbl_b = "gtfs_schedule_dim_routes",
        using_cols = ("calitp_itp_id", "calitp_url_number"),
        sel_left_cols = ["feed_key", "calitp_itp_id", "calitp_url_number"],
        sel_right_cols = ["route_key", "route_id"],
    )
}}

),

feed_route_trips AS (

{{
    scd_join(
        tbl_a = "feed_routes",
        tbl_b = "gtfs_schedule_dim_trips",
        using_cols = ("calitp_itp_id", "calitp_url_number", "route_id"),
        sel_right_cols = ["trip_key", "trip_id"],
    )

}}

),

feed_trip_stop_times AS (

{{
    scd_join(
        tbl_a = "feed_route_trips",
        tbl_b = "gtfs_schedule_dim_stop_times",
        using_cols = ("calitp_itp_id", "calitp_url_number", "trip_id"),
        sel_right_cols = ["stop_time_key", "stop_id"],
    )

}}

),

feed_trip_stops AS (

{{
    scd_join(
        tbl_a = "feed_trip_stop_times",
        tbl_b = "views.gtfs_schedule_dim_stops",
        using_cols = ("calitp_itp_id", "calitp_url_number", "stop_id"),
        sel_right_cols = ["stop_key"],
    )

}}

),

gtfs_schedule_index_feed_trip_stops AS (
    SELECT
        * EXCEPT (calitp_itp_id, calitp_url_number, route_id, trip_id, stop_id)
    FROM feed_trip_stops
)

SELECT * FROM gtfs_schedule_index_feed_trip_stops
