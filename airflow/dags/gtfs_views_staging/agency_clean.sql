---
operator: operators.SqlToWarehouseOperator
dst_table_name: "gtfs_views_staging.agency_clean"
dependencies:
  - type2_loaded

tests:
  check_null:
    - calitp_hash
    - agency_key
  check_unique:
    - agency_key
---

-- Trim all string fields
-- Incoming schema explicitly defined in gtfs_schedule_history external table definition

SELECT
    calitp_itp_id
    , calitp_url_number
    , TRIM(agency_id) as agency_id
    , TRIM(agency_name) as agency_name
    , TRIM(agency_url) as agency_url
    , TRIM(agency_timezone) as agency_timezone
    , TRIM(agency_lang) as agency_lang
    , TRIM(agency_phone) as agency_phone
    , TRIM(agency_fare_url) as agency_fare_url
    , TRIM(agency_email) as agency_email
    , calitp_extracted_at
    , calitp_hash
    , FARM_FINGERPRINT(CONCAT(CAST(calitp_hash AS STRING), "___", CAST(calitp_extracted_at AS STRING))) AS agency_key
    , COALESCE(calitp_deleted_at, "2099-01-01") AS calitp_deleted_at
FROM `gtfs_schedule_type2.agency`
