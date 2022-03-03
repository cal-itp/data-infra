---
operator: operators.SqlToWarehouseOperator

dst_table_name: gtfs_schedule.transfers

description: Latest-only table for transfers
---
{{

  get_latest_schedule_data(
    table = "transfers"
  )

}}
