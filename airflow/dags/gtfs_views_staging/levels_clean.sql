---
operator: operators.SqlToWarehouseOperator
dst_table_name: "gtfs_views_staging.levels_clean"
dependencies:
  - type2_loaded
---

-- Trim all string fields
-- Incoming schema explicitly defined in gtfs_schedule_history external table definition

SELECT
    calitp_itp_id
    , calitp_url_number
    , TRIM(level_id) as level_id
    , level_index
    , TRIM(level_name) as level_name
    , calitp_extracted_at
    , calitp_hash
    , FARM_FINGERPRINT(CONCAT(CAST(calitp_hash AS STRING), "___", CAST(calitp_extracted_at AS STRING))) AS level_key
    , COALESCE(calitp_deleted_at, "2099-01-01") AS calitp_deleted_at
FROM `gtfs_schedule_type2.levels`
