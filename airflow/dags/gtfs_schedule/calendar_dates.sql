---
operator: operators.SqlToWarehouseOperator

dst_table_name: gtfs_schedule.calendar_dates

description: Latest-only table for calendar_dates

external_dependencies:
  - gtfs_views_staging: calendar_dates_clean
---
{{

  get_latest_schedule_data(
    table = "calendar_dates"
  )

}}
