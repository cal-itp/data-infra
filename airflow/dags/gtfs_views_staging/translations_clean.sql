---
operator: operators.SqlToWarehouseOperator
dst_table_name: "gtfs_views_staging.translations_clean"
dependencies:
  - type2_loaded
---

-- no tests for translations because our test has a bug and fails when table is empty
-- see: https://github.com/cal-itp/data-infra/issues/1227

-- Trim all string fields
-- Incoming schema explicitly defined in gtfs_schedule_history external table definition

SELECT
    calitp_itp_id
    , calitp_url_number
    , TRIM(table_name) as table_name
    , TRIM(field_name) as field_name
    , TRIM(language) as language
    , TRIM(translation) as translation
    , TRIM(record_id) as record_id
    , TRIM(record_sub_id) as record_sub_id
    , TRIM(field_value) as field_value
    , calitp_extracted_at
    , calitp_hash
    , FARM_FINGERPRINT(CONCAT(CAST(calitp_hash AS STRING), "___", CAST(calitp_extracted_at AS STRING))) AS translation_key
    , COALESCE(calitp_deleted_at, "2099-01-01") AS calitp_deleted_at
FROM `gtfs_schedule_type2.translations`
