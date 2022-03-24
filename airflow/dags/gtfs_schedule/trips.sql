---
operator: operators.SqlToWarehouseOperator

dst_table_name: gtfs_schedule.trips

description: Latest-only table for trips

dependencies:
  - dummy_views_staging
---
{{

  get_latest_schedule_data(
    table = "trips"
  )

}}
