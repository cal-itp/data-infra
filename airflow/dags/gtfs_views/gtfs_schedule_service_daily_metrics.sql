---
operator: operators.SqlToWarehouseOperator
dst_table_name: "views.gtfs_schedule_service_daily_metrics"
dependencies:
  - gtfs_schedule_service_daily_trips
---

WITH service_agg AS (
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
  FROM `views.gtfs_schedule_service_daily_trips`
  WHERE is_in_service
  GROUP BY 1, 2, 3, 4
)

SELECT
  *
  , (last_arrival_ts - first_departure_ts) / 3600 AS service_window
FROM service_agg
