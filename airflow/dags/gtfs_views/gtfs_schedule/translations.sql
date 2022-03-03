---
operator: operators.SqlToWarehouseOperator

dst_table_name: gtfs_schedule.translations

description: Latest-only table for translations
---
{{

  get_latest_schedule_data(
    table = "translations"
  )

}}
