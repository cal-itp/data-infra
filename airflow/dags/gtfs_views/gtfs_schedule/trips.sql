---
operator: operators.SqlToWarehouseOperator

dst_table_name: gtfs_schedule.trips

description: Latest-only table for trips
---
{{

  get_latest_schedule_data(
    table = "trips"
  )

}}
