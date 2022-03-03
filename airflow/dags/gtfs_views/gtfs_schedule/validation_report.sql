---
operator: operators.SqlToWarehouseOperator

dst_table_name: gtfs_schedule.validation_report

description: Latest-only table for validation_report
---
{{

  get_latest_schedule_data(
    table = "validation_report"
  )

}}
