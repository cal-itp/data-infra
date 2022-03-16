---
operator: operators.SqlToWarehouseOperator

dst_table_name: gtfs_schedule.translations

description: Latest-only table for translations

external_dependencies:
  - gtfs_views_staging: translations_clean
---
{{

  get_latest_schedule_data(
    table = "translations"
  )

}}
