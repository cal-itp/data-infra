WITH external_trips AS (
    SELECT *
    FROM {{ source('external_gtfs_schedule', 'trips') }}
),

stg_gtfs_schedule__trips AS (

    -- Trim all string fields
    -- Incoming schema explicitly defined in external table definition

    SELECT
        base64_url,
        ts,
         {{ trim_make_empty_string_null('route_id') }} AS route_id,
         {{ trim_make_empty_string_null('service_id') }} AS service_id,
         {{ trim_make_empty_string_null('trip_id') }} AS trip_id,
         {{ trim_make_empty_string_null('shape_id') }} AS shape_id,
         {{ trim_make_empty_string_null('trip_headsign') }} AS trip_headsign,
         {{ trim_make_empty_string_null('trip_short_name') }} AS trip_short_name,
         SAFE_CAST({{ trim_make_empty_string_null('direction_id') }} AS INTEGER) AS direction_id,
         {{ trim_make_empty_string_null('block_id') }} AS block_id,
         SAFE_CAST({{ trim_make_empty_string_null('wheelchair_accessible') }} AS INTEGER) AS wheelchair_accessible,
         SAFE_CAST({{ trim_make_empty_string_null('bikes_allowed') }} AS INTEGER) AS bikes_allowed,
    FROM external_trips
)

SELECT * FROM stg_gtfs_schedule__trips
