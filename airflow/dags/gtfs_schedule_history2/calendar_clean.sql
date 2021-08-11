---
operator: operators.SqlToWarehouseOperator
dst_table_name: "gtfs_schedule_type2.calendar_clean"
dependencies:
  - merge_updates
---

SELECT
  * EXCEPT(start_date, end_date),
  PARSE_DATE("%Y%m%d",start_date) AS start_date,
  PARSE_DATE("%Y%m%d",end_date) AS end_date,
  FARM_FINGERPRINT(CONCAT(CAST(calitp_hash AS STRING), "___", CAST(calitp_extracted_at AS STRING))) AS calendar_key
FROM `gtfs_schedule_type2.calendar`
