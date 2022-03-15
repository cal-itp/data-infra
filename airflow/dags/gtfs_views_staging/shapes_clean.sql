---
operator: operators.SqlToWarehouseOperator
dst_table_name: "gtfs_views_staging.shapes_clean"
dependencies:
  - type2_loaded
tests:
  check_null:
    - calitp_hash
    - shape_key
  check_unique:
    - shape_key
---

-- Trim all string fields
-- Incoming schema explicitly defined in gtfs_schedule_history external table definition

SELECT
    calitp_itp_id
    , calitp_url_number
    , TRIM(shape_id) as shape_id
    , TRIM(shape_pt_lat) as shape_pt_lat
    , TRIM(shape_pt_lon) as shape_pt_lon
    , TRIM(shape_pt_sequence) as shape_pt_sequence
    , TRIM(shape_dist_traveled) as shape_dist_traveled
    , calitp_extracted_at
    , calitp_hash
    , FARM_FINGERPRINT(CONCAT(CAST(calitp_hash AS STRING), "___", CAST(calitp_extracted_at AS STRING))) AS shape_key
    , COALESCE(calitp_deleted_at, "2099-01-01") AS calitp_deleted_at
FROM `gtfs_schedule_type2.shapes`
