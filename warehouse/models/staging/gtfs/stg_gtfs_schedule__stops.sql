WITH external_stops AS (
    SELECT *
    FROM {{ source('external_gtfs_schedule', 'stops') }}
),

stg_gtfs_schedule__stops AS (

    -- Trim all string fields
    -- Incoming schema explicitly defined in gtfs_schedule_history external table definition

    SELECT
        base64_url,
        ts,
        dt AS _dt,
        {{ trim_make_empty_string_null('stop_id') }} AS stop_id,
        {{ trim_make_empty_string_null('tts_stop_name') }} AS tts_stop_name,
        SAFE_CAST({{ trim_make_empty_string_null('stop_lat') }} AS FLOAT64) AS stop_lat,
        SAFE_CAST({{ trim_make_empty_string_null('stop_lon') }} AS FLOAT64) AS stop_lon,
        {{ trim_make_empty_string_null('zone_id') }} AS zone_id,
        {{ trim_make_empty_string_null('parent_station') }} AS parent_station,
        {{ trim_make_empty_string_null('stop_code') }} AS stop_code,
        {{ trim_make_empty_string_null('stop_name') }} AS stop_name,
        {{ trim_make_empty_string_null('stop_desc') }} AS stop_desc,
        {{ trim_make_empty_string_null('stop_url') }} AS stop_url,
        SAFE_CAST({{ trim_make_empty_string_null('location_type') }} AS INTEGER) AS location_type,
        {{ trim_make_empty_string_null('stop_timezone') }} AS stop_timezone,
        SAFE_CAST({{ trim_make_empty_string_null('wheelchair_boarding') }} AS INTEGER) AS wheelchair_boarding,
        {{ trim_make_empty_string_null('level_id') }} AS level_id,
        {{ trim_make_empty_string_null('platform_code') }} AS platform_code
    FROM external_stops
)

SELECT * FROM stg_gtfs_schedule__stops
