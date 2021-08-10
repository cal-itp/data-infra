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
    , GREATEST(R.calitp_extracted_at, TST.calitp_extracted_at) AS calitp_extracted_at
    , LEAST(R.calitp_deleted_at, TST.calitp_deleted_at) AS calitp_deleted_at
  FROM trip_stops TST
  JOIN `cal-itp-data-infra.gtfs_schedule_type2.routes` R
  USING (calitp_itp_id, calitp_url_number, route_id)
  WHERE
      R.calitp_extracted_at < COALESCE(TST.calitp_deleted_at, "2099-01-01")
      AND TST.calitp_extracted_at < COALESCE(R.calitp_deleted_at, "2099-01-01")
)

SELECT * FROM route_trips
