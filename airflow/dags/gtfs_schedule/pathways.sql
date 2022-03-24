---
operator: operators.SqlToWarehouseOperator

dst_table_name: gtfs_schedule.pathways

description: Latest-only table for pathways

dependencies:
  - dummy_views_staging
---
{{

  get_latest_schedule_data(
    table = "pathways"
  )

}}
