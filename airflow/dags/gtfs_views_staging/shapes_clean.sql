---
operator: operators.SqlToWarehouseOperator
dst_table_name: "gtfs_views_staging.shapes_clean"
dependencies:
  - type2_loaded
---

-- Trim all string fields
-- Incoming schema explicitly defined in gtfs_schedule_history external table definition

SELECT
    calitp_itp_id
    , calitp_url_number
    , TRIM(shape_id) as shape_id
    , SAFE_CAST(TRIM(shape_pt_lat) as FLOAT64) as shape_pt_lat
    , SAFE_CAST(TRIM(shape_pt_lon) as FLOAT64) as shape_pt_lon
    , SAFE_CAST(TRIM(shape_pt_sequence) as INT64) as shape_pt_sequence
    , SAFE_CAST(TRIM(shape_dist_traveled) as FLOAT64) as shape_dist_traveled
    , calitp_extracted_at
    , calitp_hash
    , FARM_FINGERPRINT(CONCAT(CAST(calitp_hash AS STRING), "___", CAST(calitp_extracted_at AS STRING))) AS shape_key
    , COALESCE(calitp_deleted_at, "2099-01-01") AS calitp_deleted_at
FROM `gtfs_schedule_type2.shapes`
