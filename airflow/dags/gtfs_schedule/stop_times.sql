---
operator: operators.SqlToWarehouseOperator

dst_table_name: gtfs_schedule.stop_times

description: Latest-only table for stop_times

external_dependencies:
  - gtfs_views_staging: stop_times_clean
---
{{

  get_latest_schedule_data(
    table = "stop_times"
  )

}}
