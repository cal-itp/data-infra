---
operator: operators.SqlToWarehouseOperator
dst_table_name: "gtfs_schedule_type2.stops_clean"
dependencies:
  - type2_loaded
---

-- Trim all string fields
-- Incoming schema explicitly defined in gtfs_schedule_history external table definition

SELECT
    calitp_itp_id
    , calitp_url_number
    , TRIM(stop_id) as stop_id
    , TRIM(tts_stop_name) as tts_stop_name
    , SAFE_CAST(TRIM(stop_lat) AS FLOAT64) as stop_lat
    , SAFE_CAST(TRIM(stop_lon) AS FLOAT64) as stop_lon
    , TRIM(zone_id) as zone_id
    , TRIM(parent_station) as parent_station
    , TRIM(stop_code) as stop_code
    , TRIM(stop_name) as stop_name
    , TRIM(stop_desc) as stop_desc
    , TRIM(stop_url) as stop_url
    , TRIM(location_type) as location_type
    , TRIM(stop_timezone) as stop_timezone
    , TRIM(wheelchair_boarding) as wheelchair_boarding
    , TRIM(level_id) as level_id
    , TRIM(platform_code) as platform_code
    , calitp_extracted_at
    , calitp_hash
    , FARM_FINGERPRINT(CONCAT(CAST(calitp_hash AS STRING), "___", CAST(calitp_extracted_at AS STRING))) AS stop_key
    , COALESCE(calitp_deleted_at, "2099-01-01") AS calitp_deleted_at
FROM `gtfs_schedule_type2.stops`
