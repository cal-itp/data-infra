WITH external_levels AS (
    SELECT *
    FROM {{ source('external_gtfs_schedule', 'levels') }}
),

stg_gtfs_schedule__levels AS (

    -- Trim all string fields
    -- Incoming schema explicitly defined in gtfs_schedule_history external table definition

    -- The fields below that aren't being trimmed or cast as numeric already have their types set in the
    -- external table (to expain the inconsistencies with the rest of the staging tables)

    SELECT
        base64_url,
        ts,
        dt AS _dt,
        {{ trim_make_empty_string_null('level_id') }} AS level_id,
        level_index,
        {{ trim_make_empty_string_null('level_name') }} AS level_name
    FROM external_levels
)

SELECT * FROM stg_gtfs_schedule__levels
