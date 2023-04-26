WITH external_fare_media AS (
    SELECT *
    FROM {{ source('external_gtfs_schedule', 'fare_media') }}
),

stg_gtfs_schedule__fare_media AS (

    -- Trim all string fields
    -- Incoming schema explicitly defined in gtfs_schedule_history external table definition

    SELECT
        base64_url,
        ts,
        dt AS _dt,
        {{ trim_make_empty_string_null('fare_media_id') }} AS fare_media_id,
        {{ trim_make_empty_string_null('fare_media_name') }} AS fare_media_name,
        {{ trim_make_empty_string_null('fare_media_type') }} AS fare_media_type

    FROM external_fare_media
)

SELECT * FROM stg_gtfs_schedule__fare_media
