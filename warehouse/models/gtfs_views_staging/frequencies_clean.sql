{{ config(materialized='table') }}

WITH frequencies AS (
    SELECT *
    FROM {{ source('gtfs_type2', 'frequencies') }}
),

frequencies_clean AS (

    -- Trim all string fields
    -- Incoming schema explicitly defined in gtfs_schedule_history external table definition

    SELECT
        calitp_itp_id,
        calitp_url_number,
        TRIM(trip_id) AS trip_id,
        TRIM(start_time) AS start_time,
        TRIM(end_time) AS end_time,
        TRIM(headway_secs) AS headway_secs,
        TRIM(exact_times) AS exact_times,
        calitp_extracted_at,
        calitp_hash,
        FARM_FINGERPRINT(CONCAT(CAST(calitp_hash AS STRING), "___", CAST(calitp_extracted_at AS STRING))) AS frequency_key,
        COALESCE(calitp_deleted_at, "2099-01-01") AS calitp_deleted_at
    FROM frequencies
)

SELECT * FROM frequencies_clean
