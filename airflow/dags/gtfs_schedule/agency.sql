---
operator: operators.SqlToWarehouseOperator

dst_table_name: gtfs_schedule.agency

description: Latest-only table for agency

external_dependencies:
  - gtfs_views_staging: agency_clean
---
{{

  get_latest_schedule_data(
    table = "agency"
  )

}}
