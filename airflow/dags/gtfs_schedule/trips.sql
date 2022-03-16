---
operator: operators.SqlToWarehouseOperator

dst_table_name: gtfs_schedule.trips

description: Latest-only table for trips

external_dependencies:
  - gtfs_views_staging: trips_clean
---
{{

  get_latest_schedule_data(
    table = "trips"
  )

}}
