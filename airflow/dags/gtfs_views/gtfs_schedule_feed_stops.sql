---
operator: operators.SqlToWarehouseOperator
dst_table_name: "views.gtfs_schedule_feed_stops"
dependencies:
  - warehouse_loaded
---

WITH

stops AS (
  -- type2 join on above table and stops
  SELECT
    *
  FROM `gtfs_schedule_type2.stops_clean`
)

SELECT * FROM stops
