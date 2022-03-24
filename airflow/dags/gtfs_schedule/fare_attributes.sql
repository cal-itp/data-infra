---
operator: operators.SqlToWarehouseOperator

dst_table_name: gtfs_schedule.fare_attributes

description: Latest-only table for fare_attributes

dependencies:
  - dummy_views_staging
---
{{

  get_latest_schedule_data(
    table = "fare_attributes"
  )

}}
