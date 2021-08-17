---
operator: operators.SqlToWarehouseOperator
dst_table_name: "gtfs_schedule_type2.stops_clean"
dependencies:
  - type2_loaded
---

SELECT
    * EXCEPT(calitp_deleted_at)
    , FARM_FINGERPRINT(CONCAT(CAST(calitp_hash AS STRING), "___", CAST(calitp_extracted_at AS STRING))) AS stop_key
    , COALESCE(calitp_deleted_at, "2099-01-01") AS calitp_deleted_at
FROM `gtfs_schedule_type2.stops`
