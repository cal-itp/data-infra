{{ config(materialized='table') }}

WITH agency as (
    select *
    from {{ source('gtfs_type2', 'agency') }}
)

, agency_clean as (
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
    FROM agency
)

SELECT * FROM agency_clean
