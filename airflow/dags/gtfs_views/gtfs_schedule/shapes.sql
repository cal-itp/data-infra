---
operator: operators.SqlToWarehouseOperator

dst_table_name: gtfs_schedule.shapes

description: Latest-only table for shapes
---
{{

  get_latest_schedule_data(
    table = "shapes"
  )

}}
