{{ config(materialized='table') }}

WITH gtfs_schedule_index_feed_trip_stops AS (
    SELECT *
    FROM {{ ref('gtfs_schedule_index_feed_trip_stops') }}
),
gtfs_schedule_dim_feeds AS (
    SELECT *
    FROM {{ ref('gtfs_schedule_dim_feeds') }}
),
gtfs_schedule_dim_routes AS (
    SELECT *
    FROM {{ ref('gtfs_schedule_dim_routes') }}
),
gtfs_schedule_dim_trips AS (
    SELECT *
    FROM {{ ref('gtfs_schedule_dim_trips') }}
),
gtfs_schedule_dim_stop_times AS (
    SELECT *
    FROM {{ ref('gtfs_schedule_dim_stop_times') }}
),
gtfs_schedule_dim_stops AS (
    SELECT *
    FROM {{ ref('gtfs_schedule_dim_stops') }}
),
gtfs_schedule_data_feed_trip_stops_latest AS (
  SELECT
      Feed.calitp_itp_id
      , Feed.calitp_url_number
      , Route.route_id
      , Trip.trip_id
      , Stop.stop_id
      , * EXCEPT(calitp_itp_id, calitp_url_number, calitp_hash, calitp_extracted_at, calitp_deleted_at, route_id, trip_id, stop_id)
      , Indx.calitp_extracted_at
      , Indx.calitp_deleted_at
  FROM gtfs_schedule_index_feed_trip_stops Indx
  LEFT JOIN gtfs_schedule_dim_feeds Feed USING (feed_key)
  LEFT JOIN gtfs_schedule_dim_routes Route USING (route_key)
  LEFT JOIN gtfs_schedule_dim_trips Trip USING (trip_key)
  LEFT JOIN gtfs_schedule_dim_stop_times USING (stop_time_key)
  LEFT JOIN gtfs_schedule_dim_stops Stop USING (stop_key)
  WHERE
    Indx.calitp_extracted_at <= CURRENT_DATE()
    AND Indx.calitp_deleted_at > CURRENT_DATE()
)

SELECT * FROM gtfs_schedule_data_feed_trip_stops_latest
