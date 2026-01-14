{{
    config(
        materialized='incremental',
        unique_key = 'key',
        cluster_by='feed_key'
    )
}}

WITH dim_stop_times AS (
    SELECT *
    FROM {{ ref('dim_stop_times') }}
),

int_gtfs_schedule__frequencies_stop_times AS (
    SELECT *
    FROM {{ ref('int_gtfs_schedule__frequencies_stop_times') }}
    WHERE stop_id IS NOT NULL
),

dim_trips AS (
    SELECT DISTINCT
        feed_key,
        trip_id,
        route_id,
        direction_id
    FROM {{ ref('dim_trips') }}
),

dim_routes AS (
    SELECT DISTINCT
        feed_key,
        route_id,
        route_type
    FROM {{ ref('dim_routes') }}
),

stop_times_with_freq AS (
    SELECT
        stop_times.feed_key,
        stop_times.stop_id,
        stop_times.feed_timezone,
        stop_times.stop_sequence,
        stop_times.trip_id,
        MAX(stop_times._feed_valid_from) as _feed_valid_from,

        dim_routes.route_id,
        dim_trips.direction_id,
        COALESCE(CAST(dim_routes.route_type AS INT), 1000) AS route_type,

        MIN(COALESCE(arrival_sec, stop_times_arrival_sec)) AS arrival_sec,
        MAX(COALESCE(departure_sec, stop_times_departure_sec)) AS departure_sec,

    FROM dim_stop_times AS stop_times
    LEFT JOIN int_gtfs_schedule__frequencies_stop_times AS freq
        ON stop_times.feed_key = freq.feed_key
        AND stop_times._feed_valid_from = freq._feed_valid_from
        AND stop_times.trip_id = freq.trip_id
        AND stop_times.stop_id = freq.stop_id
        AND stop_times.stop_sequence = freq.stop_sequence
    LEFT JOIN dim_trips
        ON stop_times.feed_key = dim_trips.feed_key
        AND stop_times.trip_id = dim_trips.trip_id
    INNER JOIN dim_routes
        ON dim_trips.feed_key = dim_routes.feed_key
        AND dim_trips.route_id = dim_routes.route_id
    GROUP BY 1, 2, 3, 4, 5, 7, 8, 9
),

-- service_id for a particular service_date matters
-- if we do aggregation now, we will be overcounting because we'll count trips that aren't actually in service
stop_times_with_hour AS (
    SELECT
        -- if this is a unique key, will incremental table update by adding new stop_time entries?
        {{ dbt_utils.generate_surrogate_key(['feed_key', 'feed_timezone', 'trip_id', 'direction_id', 'route_id', 'stop_id', 'stop_sequence']) }} AS key,
        *,
        CAST(
            TRUNC(arrival_sec / 3600) AS INT
        ) AS arrival_hour,
    FROM stop_times_with_freq
)

SELECT * FROM stop_times_with_hour
