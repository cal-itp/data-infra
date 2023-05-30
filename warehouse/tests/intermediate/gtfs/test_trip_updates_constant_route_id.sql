-- test that a given trip in RT trip updates data is only associated with one route id
WITH trip_updates_grouped AS (
    SELECT *,
            -- https://gtfs.org/realtime/reference/#message-tripdescriptor
            {{ dbt_utils.generate_surrogate_key([
                'calculated_service_date',
                'base64_url',
                'trip_id',
                'trip_start_time',
            ]) }} as key
    FROM {{ ref('int_gtfs_rt__trip_updates_trip_day_map_grouping') }}
),

window_functions AS (
    SELECT DISTINCT
        key,
        FIRST_VALUE(trip_route_id)
            OVER (
                PARTITION BY key
                ORDER BY min_trip_update_timestamp
                ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
            ) AS starting_route_id,
        LAST_VALUE(trip_route_id)
            OVER (
                PARTITION BY key
                ORDER BY max_trip_update_timestamp
                ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
            ) AS ending_route_id,
    FROM trip_updates_grouped
),

bad_rows AS (
    SELECT
        key,
        starting_route_id,
        ending_route_id,
    FROM window_functions
    WHERE starting_route_id != ending_route_id
)

SELECT * FROM bad_rows
