---
operator: operators.SqlToWarehouseOperator
dst_table_name: "gtfs_views_staging.calendar_dates_clean"
dependencies:
  - type2_loaded
tests:
  check_null:
    - calitp_hash
    - calendar_dates_key
  check_unique:
    - calendar_dates_key
---

-- Trim all string fields
-- Incoming schema explicitly defined in gtfs_schedule_history external table definition

-- there are exact duplicates in files from itp id 182, url number 0, feed from 2021-09-17
-- so do a select distinct

SELECT DISTINCT
  calitp_itp_id
  , calitp_url_number
  , TRIM(service_id) as service_id
  , TRIM(exception_type) as exception_type
  , calitp_extracted_at
  , calitp_hash
  , PARSE_DATE("%Y%m%d", TRIM(date)) AS date
  , FARM_FINGERPRINT(CONCAT(CAST(calitp_hash AS STRING), "___", CAST(calitp_extracted_at AS STRING)))
        AS calendar_dates_key
  , COALESCE(calitp_deleted_at, "2099-01-01") AS calitp_deleted_at
FROM `gtfs_schedule_type2.calendar_dates`
