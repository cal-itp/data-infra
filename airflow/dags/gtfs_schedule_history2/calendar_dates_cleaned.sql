---
operator: operators.SqlToWarehouseOperator
dst_table_name: "gtfs_schedule_type2.calendar_dates_clean"
dependencies:
  - warehouse_loaded
---
SELECT
  * EXCEPT(date),
  PARSE_DATE("%Y%m%d",date) AS date,
FROM `cal-itp-data-infra-staging.gtfs_schedule_type2.calendar_dates`
