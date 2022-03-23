---
operator: operators.SqlToWarehouseOperator
dst_table_name: "views.gtfs_schedule_dim_shapes"

tests:
  check_null:
    - shape_key
  check_unique:
    - shape_key

dependencies:
  - dummy_gtfs_schedule_dims
---

  SELECT * FROM `gtfs_views_staging.shapes_clean`
