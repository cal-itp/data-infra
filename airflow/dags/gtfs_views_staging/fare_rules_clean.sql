---
operator: operators.SqlToWarehouseOperator
dst_table_name: "gtfs_views_staging.fare_rules_clean"
dependencies:
  - type2_loaded
tests:
  check_null:
    - calitp_hash
    - fare_rule_key
  check_unique:
    - fare_rule_key
---

-- Trim all string fields
-- Incoming schema explicitly defined in gtfs_schedule_history external table definition

-- SELECT DISTINCT because there are identical dups in multiple feeds

SELECT DISTINCT
    calitp_itp_id
    , calitp_url_number
    , TRIM(fare_id) as fare_id
    , TRIM(route_id) as route_id
    , TRIM(origin_id) as origin_id
    , TRIM(destination_id) as destination_id
    , TRIM(contains_id) as contains_id
    , calitp_extracted_at
    , calitp_hash
    , FARM_FINGERPRINT(CONCAT(CAST(calitp_hash AS STRING), "___", CAST(calitp_extracted_at AS STRING))) AS fare_rule_key
    , COALESCE(calitp_deleted_at, "2099-01-01") AS calitp_deleted_at
FROM `gtfs_schedule_type2.fare_rules`
