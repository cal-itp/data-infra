---
operator: operators.SqlToWarehouseOperator

dst_table_name: gtfs_schedule.fare_attributes

description: Latest-only table for fare_attributes

external_dependencies:
  - gtfs_views_staging: fare_attributes_clean
---
{{

  get_latest_schedule_data(
    table = "fare_attributes"
  )

}}
