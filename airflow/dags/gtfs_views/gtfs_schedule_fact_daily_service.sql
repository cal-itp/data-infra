---
operator: operators.SqlToWarehouseOperator
dst_table_name: "views.gtfs_schedule_fact_daily_service"

tests:
  check_null:
    - feed_key
    - service_date
    - service_id
  check_composite_unique:
    - feed_key
    - service_date
    - service_id

dependencies:
  - gtfs_schedule_fact_daily_trips
---

WITH
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
  FROM `views.gtfs_schedule_fact_daily_trips`
  WHERE is_in_service
  GROUP BY 1, 2, 3, 4
),
service_agg_keyed AS (
  SELECT
    T2.feed_key
    , T1.*
  FROM service_agg T1
  JOIN `views.gtfs_schedule_dim_feeds` T2
    ON T1.calitp_itp_id = T2.calitp_itp_id
      AND T1.calitp_url_number = T2.calitp_url_number
      AND T2.calitp_extracted_at <= service_date
      AND T2.calitp_deleted_at > service_date
)

SELECT
  *
  , (last_arrival_ts - first_departure_ts) / 3600 AS service_window
FROM service_agg_keyed
