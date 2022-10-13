WITH external_transfers AS (
    SELECT *
    FROM {{ source('external_gtfs_schedule', 'transfers') }}
),

stg_gtfs_schedule__transfers AS (

    -- Trim all string fields
    -- Incoming schema explicitly defined in gtfs_schedule_history external table definition
    -- select distinct because of several duplicates, including ITP ID 279 URL 1 on 2022-03-23
    SELECT DISTINCT
        base64_url,
        ts,
        {{ trim_make_empty_string_null('from_stop_id') }} AS from_stop_id,
        {{ trim_make_empty_string_null('to_stop_id') }} AS to_stop_id,
        SAFE_CAST({{ trim_make_empty_string_null('transfer_type') }} AS INTEGER) AS transfer_type,
        {{ trim_make_empty_string_null('from_route_id') }} AS from_route_id,
        {{ trim_make_empty_string_null('to_route_id') }} AS to_route_id,
        {{ trim_make_empty_string_null('from_trip_id') }} AS from_trip_id,
        {{ trim_make_empty_string_null('to_trip_id') }} AS to_trip_id,
        SAFE_CAST({{ trim_make_empty_string_null('min_transfer_time') }} AS INTEGER) AS min_transfer_time
    FROM external_transfers
)

SELECT * FROM stg_gtfs_schedule__transfers
