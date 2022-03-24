---
operator: operators.SqlToWarehouseOperator

dst_table_name: gtfs_schedule.fare_rules

description: Latest-only table for fare_rules

dependencies:
  - dummy_views_staging
---
{{

  get_latest_schedule_data(
    table = "fare_rules"
  )

}}
