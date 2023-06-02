WITH external_frequencies AS (
    SELECT *
    FROM {{ source('external_gtfs_schedule', 'frequencies') }}
),

stg_gtfs_schedule__frequencies AS (

    -- Trim all string fields
    -- Incoming schema explicitly defined in gtfs_schedule_history external table definition

    SELECT
        base64_url,
        ts,
        dt AS _dt,
        _line_number,
        {{ trim_make_empty_string_null('trip_id') }} AS trip_id,
        {{ trim_make_empty_string_null('start_time') }} AS start_time,
        {{ trim_make_empty_string_null('end_time') }} AS end_time,
        SAFE_CAST({{ trim_make_empty_string_null('headway_secs') }} AS INTEGER) AS headway_secs,
        SAFE_CAST({{ trim_make_empty_string_null('exact_times') }} AS INTEGER) AS exact_times
    FROM external_frequencies
)

SELECT * FROM stg_gtfs_schedule__frequencies
