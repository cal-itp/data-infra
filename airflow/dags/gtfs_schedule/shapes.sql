---
operator: operators.SqlToWarehouseOperator

dst_table_name: gtfs_schedule.shapes

description: Latest-only table for shapes

external_dependencies:
  - gtfs_views_staging: shapes_clean
---
{{

  get_latest_schedule_data(
    table = "shapes"
  )

}}
