---
operator: operators.SqlToWarehouseOperator
dst_table_name: "gtfs_views_staging.transfers_clean"
dependencies:
  - type2_loaded
tests:
  check_null:
    - calitp_hash
    - transfer_key
  check_unique:
    - transfer_key
---

-- Trim all string fields
-- Incoming schema explicitly defined in gtfs_schedule_history external table definition

-- SELECT DISTINCT because there are many fully identical dups in feed ITP ID 279, URL 0

SELECT
    calitp_itp_id
    , calitp_url_number
    , TRIM(from_stop_id) as from_stop_id
    , TRIM(to_stop_id) as to_stop_id
    , TRIM(transfer_type) as transfer_type
    , calitp_extracted_at
    , calitp_hash
    , FARM_FINGERPRINT(CONCAT(CAST(calitp_hash AS STRING), "___", CAST(calitp_extracted_at AS STRING))) AS transfer_key
    , COALESCE(calitp_deleted_at, "2099-01-01") AS calitp_deleted_at
FROM `gtfs_schedule_type2.transfers`
