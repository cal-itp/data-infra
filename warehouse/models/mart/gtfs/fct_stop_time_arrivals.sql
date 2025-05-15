{{
    config(
        materialized='table',
        partition_by={
            'field': 'service_date',
            'data_type': 'date',
            'granularity': 'day',
        },
        cluster_by='base64_url',
    )
}}

WITH fct_stop_time_updates AS (
    SELECT * FROM {{ ref('fct_stop_time_updates') }}
    WHERE dt >= '2025-05-07' AND service_date = '2025-05-08' AND gtfs_dataset_name NOT IN (
         'Bay Area 511 Regional TripUpdates',
         'BART TripUpdates',
         'Bay Area 511 Muni TripUpdates',
         'Unitrans Trip Updates'
     )
    -- TODO: these have duplicate rows down to the stop level, maybe should exclude
),

fct_tu_summaries AS (
    SELECT DISTINCT
        trip_instance_key,
        service_date,
        schedule_base64_url,
        trip_id
    FROM {{ ref('fct_trip_updates_summaries') }}
    WHERE service_date = '2025-05-08'
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
        DATETIME(TIMESTAMP_SECONDS(LAST_VALUE(arrival_time IGNORE NULLS) OVER(PARTITION BY base64_url, service_date, trip_id, trip_start_date, trip_start_time, stop_id ORDER BY COALESCE(trip_update_timestamp, header_timestamp) ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)), "America/Los_Angeles") AS last_trip_updates_arrival_time,
        DATETIME(TIMESTAMP_SECONDS(LAST_VALUE(departure_time IGNORE NULLS) OVER(PARTITION BY base64_url, service_date, trip_id, trip_start_date, trip_start_time, stop_id ORDER BY COALESCE(trip_update_timestamp, header_timestamp) ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)), "America/Los_Angeles") AS last_trip_updates_departure_time,
        LAST_VALUE(schedule_relationship IGNORE NULLS) OVER(PARTITION BY base64_url, service_date, trip_id, trip_start_date, trip_start_time, stop_id ORDER BY COALESCE(trip_update_timestamp, header_timestamp) ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS stop_schedule_relationship
    FROM fct_stop_time_updates
),

fct_stop_time_arrivals AS (
    SELECT
        stop_arrivals.*,
        fct_tu_summaries.trip_instance_key,
    FROM stop_arrivals
    LEFT JOIN fct_tu_summaries
        ON stop_arrivals.service_date = fct_tu_summaries.service_date
        AND stop_arrivals.schedule_base64_url = fct_tu_summaries.schedule_base64_url
        AND stop_arrivals.trip_id = fct_tu_summaries.trip_id
)

SELECT * FROM fct_stop_time_arrivals
