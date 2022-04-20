{{ config(materialized='table') }}

WITH stops AS (
    SELECT *
    FROM {{ source('gtfs_type2', 'stops') }}
),

stops_clean AS (

    -- Trim all string fields
    -- Incoming schema explicitly defined in gtfs_schedule_history external table definition

    SELECT
        calitp_itp_id,
        calitp_url_number,
        TRIM(stop_id) AS stop_id,
        TRIM(tts_stop_name) AS tts_stop_name,
        SAFE_CAST(TRIM(stop_lat) AS FLOAT64) AS stop_lat,
        SAFE_CAST(TRIM(stop_lon) AS FLOAT64) AS stop_lon,
        TRIM(zone_id) AS zone_id,
        TRIM(parent_station) AS parent_station,
        TRIM(stop_code) AS stop_code,
        TRIM(stop_name) AS stop_name,
        TRIM(stop_desc) AS stop_desc,
        TRIM(stop_url) AS stop_url,
        TRIM(location_type) AS location_type,
        TRIM(stop_timezone) AS stop_timezone,
        TRIM(wheelchair_boarding) AS wheelchair_boarding,
        TRIM(level_id) AS level_id,
        TRIM(platform_code) AS platform_code,
        calitp_extracted_at,
        calitp_hash,
        FARM_FINGERPRINT(CONCAT(CAST(calitp_hash AS STRING), "___", CAST(calitp_extracted_at AS STRING))) AS stop_key,
        COALESCE(calitp_deleted_at, "2099-01-01") AS calitp_deleted_at
    FROM stops
)

SELECT * FROM stops_clean
