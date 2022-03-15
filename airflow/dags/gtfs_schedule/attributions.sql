---
operator: operators.SqlToWarehouseOperator

dst_table_name: gtfs_schedule.attributions

description: Latest-only table for attributions

external_dependencies:
  - gtfs_views_staging: attributions_clean
---
{{

  get_latest_schedule_data(
    table = "attributions"
  )

}}
