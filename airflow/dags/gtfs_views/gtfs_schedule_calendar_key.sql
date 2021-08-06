---
operator: operators.SqlToWarehouseOperator
dst_table_name: "views.gtfs_schedule_type2_calendar"
dependencies:
  - warehouse_loaded
---


SELECT
  * EXCEPT(start_date, end_date),
  PARSE_DATE("%Y%m%d",start_date) AS start_date,
  PARSE_DATE("%Y%m%d",end_date) AS end_date,
FARM_FINGERPRINT(CONCAT(CAST(calitp_hash AS STRING), "___", CAST(calitp_extracted_at AS STRING))) AS calendar_key
FROM `cal-itp-data-infra-staging.gtfs_schedule_type2.calendar`