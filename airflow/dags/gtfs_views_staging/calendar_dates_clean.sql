---
operator: operators.SqlToWarehouseOperator
dst_table_name: "gtfs_schedule_type2.calendar_dates_clean"
dependencies:
  - type2_loaded
---
SELECT
  * EXCEPT(date, calitp_deleted_at, service_id)
  , TRIM(service_id) as service_id
  , PARSE_DATE("%Y%m%d",date) AS date
  , COALESCE(calitp_deleted_at, "2099-01-01") AS calitp_deleted_at
FROM `gtfs_schedule_type2.calendar_dates`
