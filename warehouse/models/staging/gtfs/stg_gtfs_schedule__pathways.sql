WITH external_pathways AS (
    SELECT *
    FROM {{ source('external_gtfs_schedule', 'pathways') }}
),

stg_gtfs_schedule__pathways AS (

    -- Trim all string fields
    -- Incoming schema explicitly defined in gtfs_schedule_history external table definition

    -- The fields below that aren't being trimmed or cast as numeric already have their types set in the
    -- external table (to expain the inconsistencies with the rest of the staging tables)
    SELECT
        base64_url,
        ts,
        dt AS _dt,
        {{ trim_make_empty_string_null('pathway_id') }} AS pathway_id,
        {{ trim_make_empty_string_null('from_stop_id') }} AS from_stop_id,
        {{ trim_make_empty_string_null('to_stop_id') }} AS to_stop_id,
        pathway_mode,
        is_bidirectional,
        length,
        traversal_time,
        stair_count,
        max_slope,
        min_width,
        {{ trim_make_empty_string_null('signposted_as') }} AS signposted_as,
        {{ trim_make_empty_string_null('reversed_signposted_as') }} AS reversed_signposted_as
    FROM external_pathways
)

SELECT * FROM stg_gtfs_schedule__pathways
