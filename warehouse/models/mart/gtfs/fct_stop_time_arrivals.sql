{{
    config(
        partition_by = {
            'field': 'service_date',
            'data_type': 'date',
            'granularity': 'day',
        },
        cluster_by='base64_url',
    )
}}


WITH fct_stop_time_updates AS (
    SELECT * FROM {{ ref('fct_stop_time_updates') }}
    -- TODO: these have duplicate rows down to the stop level, maybe should exclude
    WHERE gtfs_dataset_name NOT IN (
         'Bay Area 511 Regional TripUpdates',
         'BART TripUpdates',
         'Bay Area 511 Muni TripUpdates',
         'Unitrans Trip Updates'
     )
),

stop_arrivals AS (
    SELECT DISTINCT
        gtfs_dataset_key,
        gtfs_dataset_name,
        base64_url,
        schedule_base64_url,
        service_date,
        trip_id,
        stop_id,
        trip_start_date,
        trip_start_time,
        trip_direction_id,
        trip_route_id,
        trip_schedule_relationship,

        -- last arrival and departure as UTC
        DATETIME(TIMESTAMP_SECONDS(LAST_VALUE(arrival_time IGNORE NULLS) OVER(PARTITION BY base64_url, service_date, trip_id, trip_start_date, trip_start_time, stop_id ORDER BY COALESCE(trip_update_timestamp, header_timestamp) ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING))) AS last_trip_updates_arrival,
        DATETIME(TIMESTAMP_SECONDS(LAST_VALUE(departure_time IGNORE NULLS) OVER(PARTITION BY base64_url, service_date, trip_id, trip_start_date, trip_start_time, stop_id ORDER BY COALESCE(trip_update_timestamp, header_timestamp) ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING))) AS last_trip_updates_departure,
        -- last arrival and departure as Pacific
        DATETIME(TIMESTAMP_SECONDS(LAST_VALUE(arrival_time IGNORE NULLS) OVER(PARTITION BY base64_url, service_date, trip_id, trip_start_date, trip_start_time, stop_id ORDER BY COALESCE(trip_update_timestamp, header_timestamp) ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)), "America/Los_Angeles") AS last_trip_updates_arrival_pacific,
        DATETIME(TIMESTAMP_SECONDS(LAST_VALUE(departure_time IGNORE NULLS) OVER(PARTITION BY base64_url, service_date, trip_id, trip_start_date, trip_start_time, stop_id ORDER BY COALESCE(trip_update_timestamp, header_timestamp) ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)), "America/Los_Angeles") AS last_trip_updates_departure_pacific,

    FROM fct_stop_time_updates
),

fct_stop_time_arrivals AS (
    SELECT
        stop_arrivals.*,
        -- usually one of these columns is null, but we want to use it to compare against _extract_ts
        COALESCE(last_trip_updates_arrival_pacific, last_trip_updates_departure_pacific) AS actual_arrival_pacific,
        COALESCE(last_trip_updates_arrival, last_trip_updates_departure) AS actual_arrival,
    FROM stop_arrivals
)

SELECT * FROM fct_stop_time_arrivals
