WITH external_feed_info AS (
    SELECT *
    FROM {{ source('external_gtfs_schedule', 'feed_info') }}
),

stg_gtfs_schedule__feed_info AS (

    -- Trim all string fields
    -- Incoming schema explicitly defined in gtfs_schedule_history external table definition

    -- select distinct because of Foothill Transit feed with exact duplicates
    -- duplicates here result in duplicate feed_keys downstream
    SELECT DISTINCT
        base64_url,
        ts,
        {{ trim_make_empty_string_null('feed_publisher_name') }} AS feed_publisher_name,
        {{ trim_make_empty_string_null('feed_publisher_url') }} AS feed_publisher_url,
        {{ trim_make_empty_string_null('feed_lang') }} AS feed_lang,
        {{ trim_make_empty_string_null('default_lang') }} AS default_lang,
        {{ trim_make_empty_string_null('feed_version') }} AS feed_version,
        {{ trim_make_empty_string_null('feed_contact_email') }} AS feed_contact_email,
        {{ trim_make_empty_string_null('feed_contact_url') }} AS feed_contact_url,
        PARSE_DATE("%Y%m%d", {{ trim_make_empty_string_null('feed_start_date') }}) AS feed_start_date,
        PARSE_DATE("%Y%m%d", {{ trim_make_empty_string_null('feed_end_date') }}) AS feed_end_date
    FROM external_feed_info
)

SELECT * FROM stg_gtfs_schedule__feed_info
