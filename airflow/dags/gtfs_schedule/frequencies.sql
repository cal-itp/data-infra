---
operator: operators.SqlToWarehouseOperator

dst_table_name: gtfs_schedule.frequencies

description: Latest-only table for frequencies

external_dependencies:
  - gtfs_views_staging: frequencies_clean
---
{{

  get_latest_schedule_data(
    table = "frequencies"
  )

}}
