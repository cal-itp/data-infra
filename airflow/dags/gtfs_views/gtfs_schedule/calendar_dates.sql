---
operator: operators.SqlToWarehouseOperator

dst_table_name: gtfs_schedule.calendar_dates

description: Latest-only table for calendar_dates
---
{{

  get_latest_schedule_data(
    table = "calendar_dates"
  )

}}
