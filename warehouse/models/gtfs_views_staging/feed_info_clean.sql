{{ config(materialized='table') }}

WITH feed_info as (
    select *
    from {{ source('gtfs_type2', 'feed_info') }}
)

, feed_info_clean as (

    -- Trim all string fields
    -- Incoming schema explicitly defined in gtfs_schedule_history external table definition

    -- select distinct because of Foothill Transit feed with exact duplicates
    -- duplicates here result in duplicate feed_keys downstream
    SELECT DISTINCT
        calitp_itp_id
        , calitp_url_number
        , TRIM(feed_publisher_name) as feed_publisher_name
        , TRIM(feed_publisher_url) as feed_publisher_url
        , TRIM(feed_lang) as feed_lang
        , TRIM(default_lang) as default_lang
        , TRIM(feed_version) as feed_version
        , TRIM(feed_contact_email) as feed_contact_email
        , TRIM(feed_contact_url) as feed_contact_url
        , calitp_extracted_at
        , calitp_hash
        , PARSE_DATE("%Y%m%d", TRIM(feed_start_date)) AS feed_start_date
        , PARSE_DATE("%Y%m%d", TRIM(feed_end_date)) AS feed_end_date
        , FARM_FINGERPRINT(CONCAT(CAST(calitp_hash AS STRING), "___", CAST(calitp_extracted_at AS STRING)))
            AS feed_info_key
        , COALESCE(calitp_deleted_at, "2099-01-01") AS calitp_deleted_at
    FROM feed_info
)

SELECT * FROM feed_info_clean
