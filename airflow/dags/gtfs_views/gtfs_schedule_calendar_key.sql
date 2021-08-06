---
operator: operators.SqlToWarehouseOperator
dst_table_name: "views.gtfs_schedule_type2_calendar_cleaned"
dependencies:
  - warehouse_loaded
---

SELECT *,
FARM_FINGERPRINT(CONCAT(CAST(calitp_hash AS STRING), "___", CAST(calitp_extracted_at AS STRING))) AS calendar_key
FROM `cal-itp-data-infra-staging.gtfs_schedule_type2.calendar_cleaned`
