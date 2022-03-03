---
operator: operators.SqlToWarehouseOperator

dst_table_name: gtfs_schedule.calendar

description: Latest-only table for calendar
---
{{

  get_latest_schedule_data(
    table = "calendar"
  )

}}
