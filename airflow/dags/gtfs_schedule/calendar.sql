---
operator: operators.SqlToWarehouseOperator

dst_table_name: gtfs_schedule.calendar

description: Latest-only table for calendar

dependencies:
  - dummy_views_staging
---
{{

  get_latest_schedule_data(
    table = "calendar"
  )

}}
