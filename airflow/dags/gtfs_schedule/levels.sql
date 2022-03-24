---
operator: operators.SqlToWarehouseOperator

dst_table_name: gtfs_schedule.levels

description: Latest-only table for levels

dependencies:
  - dummy_views_staging
---
{{

  get_latest_schedule_data(
    table = "levels"
  )

}}
