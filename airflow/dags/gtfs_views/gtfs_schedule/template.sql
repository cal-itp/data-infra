---
operator: operators.SqlToWarehouseOperator

dst_table_name: gtfs_schedule.{table_name}

description: Latest-only table for {table_name}
---
{{{

  get_latest_schedule_data(
    table = "{table_name}"
  )

}}}
