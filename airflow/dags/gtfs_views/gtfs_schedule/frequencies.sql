---
operator: operators.SqlToWarehouseOperator

dst_table_name: gtfs_schedule.frequencies

description: Latest-only table for frequencies
---
{{

  get_latest_schedule_data(
    table = "frequencies"
  )

}}
