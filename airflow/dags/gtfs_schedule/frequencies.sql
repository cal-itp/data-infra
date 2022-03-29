---
operator: operators.SqlToWarehouseOperator

dst_table_name: gtfs_schedule.frequencies

description: Latest-only table for frequencies

dependencies:
  - dummy_views_staging
---
{{

  get_latest_schedule_data(
    table = "frequencies"
  )

}}
