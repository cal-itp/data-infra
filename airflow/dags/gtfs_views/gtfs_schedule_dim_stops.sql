---
operator: operators.SqlToWarehouseOperator
dst_table_name: "views.gtfs_schedule_dim_stops"

tests:
  check_null:
    - stop_key
  check_unique:
    - stop_key

dependencies:
  - dummy_gtfs_schedule_dims
---

  SELECT * FROM `gtfs_views_staging.stops_clean`
