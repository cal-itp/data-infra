---
operator: operators.SqlToWarehouseOperator

dst_table_name: gtfs_schedule.stops

description: Latest-only table for stops
---
{{

  get_latest_schedule_data(
    table = "stops"
  )

}}
