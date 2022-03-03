---
operator: operators.SqlToWarehouseOperator

dst_table_name: gtfs_schedule.agency

description: Latest-only table for agency
---
{{

  get_latest_schedule_data(
    table = "agency"
  )

}}
