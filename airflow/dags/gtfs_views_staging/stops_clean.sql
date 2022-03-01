---
operator: operators.SqlToWarehouseOperator
dst_table_name: "gtfs_schedule_type2.stops_clean"
dependencies:
  - type2_loaded
---

SELECT
    * EXCEPT(calitp_deleted_at, stop_lat, stop_lon)
    , SAFE_CAST(stop_lat AS FLOAT64)
    , SAFE_CAST(stop_lon AS FLOAT64)
    , FARM_FINGERPRINT(CONCAT(CAST(calitp_hash AS STRING), "___", CAST(calitp_extracted_at AS STRING))) AS stop_key
    , COALESCE(calitp_deleted_at, "2099-01-01") AS calitp_deleted_at
FROM `gtfs_schedule_type2.stops`
