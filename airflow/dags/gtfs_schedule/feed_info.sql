---
operator: operators.SqlToWarehouseOperator

dst_table_name: gtfs_schedule.feed_info

description: Latest-only table for feed_info

dependencies:
  - dummy_views_staging
---
{{

  get_latest_schedule_data(
    table = "feed_info"
  )

}}
