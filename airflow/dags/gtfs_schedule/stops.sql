---
operator: operators.SqlToWarehouseOperator

dst_table_name: gtfs_schedule.stops

description: Latest-only table for stops

external_dependencies:
  - gtfs_views_staging: stops_clean
---
{{

  get_latest_schedule_data(
    table = "stops"
  )

}}
