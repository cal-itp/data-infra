---
operator: operators.SqlToWarehouseOperator

dst_table_name: gtfs_schedule.attributions

description: Latest-only table for attributions

dependencies:
  - dummy_views_staging
---
{{

  get_latest_schedule_data(
    table = "attributions"
  )

}}
