WITH external_stop_areas AS (
    SELECT *
    FROM {{ source('external_gtfs_schedule', 'stop_areas') }}
),

stg_gtfs_schedule__stop_areas AS (

    -- Trim all string fields
    -- Incoming schema explicitly defined in gtfs_schedule_history external table definition

    SELECT
        base64_url,
        ts,
        dt AS _dt,
        {{ trim_make_empty_string_null('area_id') }} AS area_id,
        {{ trim_make_empty_string_null('stop_id') }} AS stop_id
    FROM external_stop_areas
)

SELECT * FROM stg_gtfs_schedule__stop_areas
