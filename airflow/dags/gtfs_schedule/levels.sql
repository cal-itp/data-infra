---
operator: operators.SqlToWarehouseOperator

dst_table_name: gtfs_schedule.levels

description: Latest-only table for levels

external_dependencies:
  - gtfs_views_staging: levels_clean
---
{{

  get_latest_schedule_data(
    table = "levels"
  )

}}
