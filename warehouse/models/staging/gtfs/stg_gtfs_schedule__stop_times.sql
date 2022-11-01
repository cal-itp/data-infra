WITH external_stop_times AS (
    SELECT *
    FROM {{ source('external_gtfs_schedule', 'stop_times') }}
),

stg_gtfs_schedule__stop_times AS (

    -- Trim all string fields
    -- Incoming schema explicitly defined in gtfs_schedule_history external table definition

    SELECT
        base64_url,
        ts,
        {{ trim_make_empty_string_null('trip_id') }} AS trip_id,
        {{ trim_make_empty_string_null('stop_id') }} AS stop_id,
        SAFE_CAST({{ trim_make_empty_string_null('stop_sequence') }} AS INTEGER) AS stop_sequence,
        {{ trim_make_empty_string_null('arrival_time') }} AS arrival_time,
        {{ trim_make_empty_string_null('departure_time') }} AS departure_time,
        {{ trim_make_empty_string_null('stop_headsign') }} AS stop_headsign,
        SAFE_CAST({{ trim_make_empty_string_null('pickup_type') }} AS INTEGER) AS pickup_type,
        SAFE_CAST({{ trim_make_empty_string_null('drop_off_type') }} AS INTEGER) AS drop_off_type,
        SAFE_CAST({{ trim_make_empty_string_null('continuous_pickup') }} AS INTEGER) AS continuous_pickup,
        SAFE_CAST({{ trim_make_empty_string_null('continuous_drop_off') }} AS INTEGER) AS continuous_drop_off,
        SAFE_CAST({{ trim_make_empty_string_null('shape_dist_traveled') }} AS FLOAT64) AS shape_dist_traveled,
        SAFE_CAST({{ trim_make_empty_string_null('timepoint') }} AS INTEGER) AS timepoint
    FROM external_stop_times
)

SELECT * FROM stg_gtfs_schedule__stop_times
