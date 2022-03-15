---
operator: operators.SqlToWarehouseOperator

dst_table_name: gtfs_schedule.routes

description: Latest-only table for routes

external_dependencies:
  - gtfs_views_staging: routes_clean
---
{{

  get_latest_schedule_data(
    table = "routes"
  )

}}
