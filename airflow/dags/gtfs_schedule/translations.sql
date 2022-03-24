---
operator: operators.SqlToWarehouseOperator

dst_table_name: gtfs_schedule.translations

description: Latest-only table for translations

dependencies:
  - dummy_views_staging
---
{{

  get_latest_schedule_data(
    table = "translations"
  )

}}
