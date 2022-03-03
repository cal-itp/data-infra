---
operator: operators.SqlToWarehouseOperator

dst_table_name: gtfs_schedule.routes

description: Latest-only table for routes
---
{{

  get_latest_schedule_data(
    table = "routes"
  )

}}
