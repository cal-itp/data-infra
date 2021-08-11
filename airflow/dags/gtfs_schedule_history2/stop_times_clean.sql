---
operator: operators.SqlToWarehouseOperator
dst_table_name: "gtfs_schedule_type2.stop_times_clean"
dependencies:
  - merge_updates
---

SELECT
    *
    , FARM_FINGERPRINT(CONCAT(CAST(calitp_hash AS STRING), "___", CAST(calitp_extracted_at AS STRING))) AS stop_times_key
FROM `gtfs_schedule_type2.stop_times`
