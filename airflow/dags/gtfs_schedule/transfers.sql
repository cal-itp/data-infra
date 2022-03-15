---
operator: operators.SqlToWarehouseOperator

dst_table_name: gtfs_schedule.transfers

description: Latest-only table for transfers

external_dependencies:
  - gtfs_views_staging: transfers_clean
---
{{

  get_latest_schedule_data(
    table = "transfers"
  )

}}
