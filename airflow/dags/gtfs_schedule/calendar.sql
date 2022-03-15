---
operator: operators.SqlToWarehouseOperator

dst_table_name: gtfs_schedule.calendar

description: Latest-only table for calendar

external_dependencies:
  - gtfs_views_staging: calendar_clean
---
{{

  get_latest_schedule_data(
    table = "calendar"
  )

}}
