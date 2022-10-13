WITH external_fare_rules AS (
    SELECT *
    FROM {{ source('external_gtfs_schedule', 'fare_rules') }}
),

stg_gtfs_schedule__fare_rules AS (

    -- Trim all string fields
    -- Incoming schema explicitly defined in gtfs_schedule_history external table definition
    -- select distinct because of several instances of full duplicates, ex. ITP ID 294, URL 1 on 2022-03-09
    SELECT DISTINCT
        base64_url,
        ts,
        {{ trim_make_empty_string_null('fare_id') }} AS fare_id,
        {{ trim_make_empty_string_null('route_id') }} AS route_id,
        {{ trim_make_empty_string_null('origin_id') }} AS origin_id,
        {{ trim_make_empty_string_null('destination_id') }} AS destination_id,
        {{ trim_make_empty_string_null('contains_id') }} AS contains_id
    FROM external_fare_rules
)

SELECT * FROM stg_gtfs_schedule__fare_rules
