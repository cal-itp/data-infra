---
operator: operators.SqlToWarehouseOperator
dst_table_name: "gtfs_schedule_type2.calendar_dates_clean"
dependencies:
  - merge_updates
---
SELECT
  * EXCEPT(date)
  , PARSE_DATE("%Y%m%d",date) AS date,
FROM `gtfs_schedule_type2.calendar_dates`
