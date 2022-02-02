---
operator: operators.SqlToWarehouseOperator
dst_table_name: "gtfs_schedule_type2.calendar_clean"
dependencies:
  - type2_loaded
---

SELECT
    * EXCEPT(start_date, end_date, calitp_deleted_at, service_id),
    TRIM(service_id) as service_id,
    PARSE_DATE("%Y%m%d",start_date) AS start_date,
    PARSE_DATE("%Y%m%d",end_date) AS end_date,
    FARM_FINGERPRINT(CONCAT(CAST(calitp_hash AS STRING), "___", CAST(calitp_extracted_at AS STRING)))
        AS calendar_key,
    COALESCE(calitp_deleted_at, "2099-01-01") AS calitp_deleted_at
FROM `gtfs_schedule_type2.calendar`
