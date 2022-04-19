{{ config(materialized='table') }}

WITH feed_info AS (
    SELECT *
    FROM {{ source('gtfs_type2', 'feed_info') }}
),

feed_info_clean AS (

    -- Trim all string fields
    -- Incoming schema explicitly defined in gtfs_schedule_history external table definition

    -- select distinct because of Foothill Transit feed with exact duplicates
    -- duplicates here result in duplicate feed_keys downstream
    SELECT DISTINCT
        calitp_itp_id,
        calitp_url_number,
        TRIM(feed_publisher_name) AS feed_publisher_name,
        TRIM(feed_publisher_url) AS feed_publisher_url,
        TRIM(feed_lang) AS feed_lang,
        TRIM(default_lang) AS default_lang,
        TRIM(feed_version) AS feed_version,
        TRIM(feed_contact_email) AS feed_contact_email,
        TRIM(feed_contact_url) AS feed_contact_url,
        calitp_extracted_at,
        calitp_hash,
        PARSE_DATE("%Y%m%d", TRIM(feed_start_date)) AS feed_start_date,
        PARSE_DATE("%Y%m%d", TRIM(feed_end_date)) AS feed_end_date,
        FARM_FINGERPRINT(CONCAT(CAST(calitp_hash AS STRING), "___", CAST(calitp_extracted_at AS STRING)))
        AS feed_info_key,
        COALESCE(calitp_deleted_at, "2099-01-01") AS calitp_deleted_at
    FROM feed_info
)

SELECT * FROM feed_info_clean
