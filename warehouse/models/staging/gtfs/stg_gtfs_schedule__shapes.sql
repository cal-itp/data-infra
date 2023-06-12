WITH external_shapes AS (
    SELECT *
    FROM {{ source('external_gtfs_schedule', 'shapes') }}
),

stg_gtfs_schedule__shapes AS (

    -- Trim all string fields
    -- Incoming schema explicitly defined in gtfs_schedule_history external table definition

    SELECT
        base64_url,
        ts,
        dt AS _dt,
        _line_number,
        {{ trim_make_empty_string_null('shape_id') }} AS shape_id,
        SAFE_CAST({{ trim_make_empty_string_null('shape_pt_lat') }} AS NUMERIC) AS shape_pt_lat,
        SAFE_CAST({{ trim_make_empty_string_null('shape_pt_lon') }} AS NUMERIC) AS shape_pt_lon,
        SAFE_CAST({{ trim_make_empty_string_null('shape_pt_sequence') }} AS INT64) AS shape_pt_sequence,
        SAFE_CAST({{ trim_make_empty_string_null('shape_dist_traveled') }} AS NUMERIC) AS shape_dist_traveled
    FROM external_shapes
)

SELECT * FROM stg_gtfs_schedule__shapes
