---
operator: operators.SqlToWarehouseOperator

dst_table_name: gtfs_schedule.validation_notices

description: Latest-only table for validation_notices

external_dependencies:
  - gtfs_views_staging: validation_notices_clean
---
{{

  get_latest_schedule_data(
    table = "validation_notices"
  )

}}
