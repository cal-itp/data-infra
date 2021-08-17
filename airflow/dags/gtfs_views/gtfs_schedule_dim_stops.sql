---
operator: operators.SqlToWarehouseOperator
dst_table_name: "views.gtfs_schedule_dim_stops"
dependencies:
  - dummy_gtfs_schedule_dims
---

  SELECT * FROM `gtfs_schedule_type2.stops_clean`
