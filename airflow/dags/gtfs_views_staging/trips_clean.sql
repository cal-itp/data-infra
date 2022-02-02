---
operator: operators.SqlToWarehouseOperator
dst_table_name: "gtfs_schedule_type2.trips_clean"
dependencies:
  - type2_loaded
---
-- Trim service_id for 273, 271 specific issue
SELECT
    * EXCEPT(calitp_deleted_at, service_id)
    , TRIM(service_id) as service_id
    , FARM_FINGERPRINT(CONCAT(CAST(calitp_hash AS STRING), "___", CAST(calitp_extracted_at AS STRING))) AS trip_key
    , COALESCE(calitp_deleted_at, "2099-01-01") AS calitp_deleted_at
FROM `gtfs_schedule_type2.trips`
