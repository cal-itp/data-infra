{{ config(materialized='table') }}

WITH gtfs_schedule_fact_daily_trips AS (
    SELECT *
    FROM {{ ref('gtfs_schedule_fact_daily_trips') }}
),
gtfs_schedule_dim_feeds AS (
    SELECT *
    FROM {{ ref('gtfs_schedule_dim_feeds') }}
),
service_agg AS (
  SELECT
    calitp_itp_id
    , calitp_url_number
    , service_date
    , service_id
    , SUM(service_hours) AS ttl_service_hours
    , COUNT(DISTINCT trip_id) AS n_trips
    , COUNT(DISTINCT route_id) AS n_routes
    , MIN(trip_first_departure_ts) AS first_departure_ts
    , MAX(trip_last_arrival_ts) AS last_arrival_ts
  FROM gtfs_schedule_fact_daily_trips
  WHERE is_in_service
  GROUP BY 1, 2, 3, 4
),
service_agg_keyed AS (
  SELECT
    T2.feed_key
    , T1.*
  FROM service_agg T1
  JOIN gtfs_schedule_dim_feeds T2
    ON T1.calitp_itp_id = T2.calitp_itp_id
      AND T1.calitp_url_number = T2.calitp_url_number
      AND T2.calitp_extracted_at <= service_date
      AND T2.calitp_deleted_at > service_date
),
gtfs_schedule_fact_daily_service AS (
  SELECT
    *
    , (last_arrival_ts - first_departure_ts) / 3600 AS service_window
  FROM service_agg_keyed
)

SELECT * FROM gtfs_schedule_fact_daily_service
