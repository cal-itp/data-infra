---
operator: operators.SqlToWarehouseOperator
dst_table_name: "gtfs_views_staging.frequencies_clean"
dependencies:
  - type2_loaded
---

-- Trim all string fields
-- Incoming schema explicitly defined in gtfs_schedule_history external table definition

SELECT
    calitp_itp_id
    , calitp_url_number
    , TRIM(trip_id) as trip_id
    , TRIM(start_time) as start_time
    , TRIM(end_time) as end_time
    , TRIM(headway_secs) as headway_secs
    , TRIM(exact_times) as exact_times
    , calitp_extracted_at
    , calitp_hash
    , FARM_FINGERPRINT(CONCAT(CAST(calitp_hash AS STRING), "___", CAST(calitp_extracted_at AS STRING))) AS frequency_key
    , COALESCE(calitp_deleted_at, "2099-01-01") AS calitp_deleted_at
FROM `gtfs_schedule_type2.frequencies`
