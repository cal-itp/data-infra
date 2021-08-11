---
operator: operators.SqlToWarehouseOperator
dst_table_name: "views.gtfs_schedule_feed_route_trips"
dependencies:
  - warehouse_loaded
---

WITH

route_trips AS (
  -- type2 join on above table and routes
  SELECT
    * EXCEPT(calitp_extracted_at, calitp_deleted_at, calitp_hash, continuous_pickup, continuous_drop_off)
    , continuous_pickup AS route_continuous_pickup
    , continuous_drop_off AS route_continuous_drop_off
    , GREATEST(R.calitp_extracted_at, T.calitp_extracted_at) AS calitp_extracted_at
    , LEAST(R.calitp_deleted_at, T.calitp_deleted_at) AS calitp_deleted_at
  FROM `gtfs_schedule_type2.trips_clean` T
  JOIN `gtfs_schedule_type2.routes_clean` R
  USING (calitp_itp_id, calitp_url_number, route_id)
  WHERE
      R.calitp_extracted_at < COALESCE(T.calitp_deleted_at, "2099-01-01")
      AND T.calitp_extracted_at < COALESCE(R.calitp_deleted_at, "2099-01-01")
)

SELECT * FROM route_trips
