---
operator: operators.SqlToWarehouseOperator

dst_table_name: gtfs_schedule.pathways

description: Latest-only table for pathways

external_dependencies:
  - gtfs_views_staging: pathways_clean
---
{{

  get_latest_schedule_data(
    table = "pathways"
  )

}}
