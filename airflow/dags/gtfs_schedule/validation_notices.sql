---
operator: operators.SqlToWarehouseOperator

dst_table_name: gtfs_schedule.validation_notices

description: Latest-only table for validation_notices

dependencies:
  - dummy_views_staging
---
{{

  get_latest_schedule_data(
    table = "validation_notices"
  )

}}
