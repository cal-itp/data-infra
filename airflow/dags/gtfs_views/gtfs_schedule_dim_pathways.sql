---
operator: operators.SqlToWarehouseOperator
dst_table_name: "views.gtfs_schedule_dim_pathways"

tests:
  check_null:
    - pathway_key
  check_unique:
    - pathway_key

dependencies:
  - dummy_gtfs_schedule_dims
---

  SELECT * FROM `gtfs_views_staging.pathways_clean`
