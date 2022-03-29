---
operator: operators.SqlToWarehouseOperator

dst_table_name: gtfs_schedule.stop_times

description: Latest-only table for stop_times

dependencies:
  - dummy_views_staging
---
{{

  get_latest_schedule_data(
    table = "stop_times"
  )

}}
