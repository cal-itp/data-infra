---
operator: operators.SqlToWarehouseOperator
dst_table_name: "gtfs_schedule_type2.calendar_clean"
dependencies:
  - type2_loaded
---

-- Trim all string fields
-- Incoming schema explicitly defined in gtfs_schedule_history external table definition

SELECT
    calitp_itp_id
    , calitp_url_number
    , TRIM(service_id) as service_id
    , TRIM(monday) as monday
    , TRIM(tuesday) as tuesday
    , TRIM(wednesday) as wednesday
    , TRIM(thursday) as thursday
    , TRIM(friday) as friday
    , TRIM(saturday) as saturday
    , TRIM(sunday) as sunday
    , PARSE_DATE("%Y%m%d", TRIM(start_date)) AS start_date
    , PARSE_DATE("%Y%m%d", TRIM(end_date)) AS end_date
    , calitp_extracted_at
    , calitp_hash
    , FARM_FINGERPRINT(CONCAT(CAST(calitp_hash AS STRING), "___", CAST(calitp_extracted_at AS STRING)))
        AS calendar_key
    , COALESCE(calitp_deleted_at, "2099-01-01") AS calitp_deleted_at
FROM `gtfs_schedule_type2.calendar`
