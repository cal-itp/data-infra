---
operator: operators.SqlToWarehouseOperator

dst_table_name: gtfs_schedule.fare_rules

description: Latest-only table for fare_rules

external_dependencies:
  - gtfs_views_staging: fare_rules_clean
---
{{

  get_latest_schedule_data(
    table = "fare_rules"
  )

}}
