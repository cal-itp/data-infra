---
operator: operators.SqlToWarehouseOperator

dst_table_name: gtfs_schedule.routes

description: Latest-only table for routes

dependencies:
  - dummy_views_staging
---
{{

  get_latest_schedule_data(
    table = "routes"
  )

}}
