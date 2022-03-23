---
operator: operators.SqlToWarehouseOperator

dst_table_name: gtfs_schedule.feed_info

description: Latest-only table for feed_info

external_dependencies:
  - gtfs_views_staging: feed_info_clean
---
{{

  get_latest_schedule_data(
    table = "feed_info"
  )

}}
