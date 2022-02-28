---
operator: operators.SqlToWarehouseOperator
dst_table_name: "gtfs_views_staging.calendar_dates_clean"
dependencies:
  - type2_loaded
---

-- Trim all string fields
-- Incoming schema explicitly defined in gtfs_schedule_history external table definition

SELECT
  calitp_itp_id
  , calitp_url_number
  , TRIM(service_id) as service_id
  , TRIM(exception_type) as exception_type
  , calitp_extracted_at
  , calitp_hash
  , PARSE_DATE("%Y%m%d", TRIM(date)) AS date
  , COALESCE(calitp_deleted_at, "2099-01-01") AS calitp_deleted_at
FROM `gtfs_schedule_type2.calendar_dates`
