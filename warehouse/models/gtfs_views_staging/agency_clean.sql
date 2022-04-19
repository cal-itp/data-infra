{{ config(materialized='table') }}

WITH agency AS (
    SELECT *
    FROM {{ source('gtfs_type2', 'agency') }}
),

agency_clean AS (
    -- Trim all string fields
    -- Incoming schema explicitly defined in gtfs_schedule_history external table definition

    SELECT
        calitp_itp_id,
        calitp_url_number,
        TRIM(agency_id) AS agency_id,
        TRIM(agency_name) AS agency_name,
        TRIM(agency_url) AS agency_url,
        TRIM(agency_timezone) AS agency_timezone,
        TRIM(agency_lang) AS agency_lang,
        TRIM(agency_phone) AS agency_phone,
        TRIM(agency_fare_url) AS agency_fare_url,
        TRIM(agency_email) AS agency_email,
        calitp_extracted_at,
        calitp_hash,
        FARM_FINGERPRINT(CONCAT(CAST(calitp_hash AS STRING), "___", CAST(calitp_extracted_at AS STRING))) AS agency_key,
        COALESCE(calitp_deleted_at, "2099-01-01") AS calitp_deleted_at
    FROM agency
)

SELECT * FROM agency_clean
