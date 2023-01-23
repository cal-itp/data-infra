{{
    config(
        materialized='incremental',
        incremental_strategy='insert_overwrite',
        partition_by={
            'field': 'date',
            'data_type': 'date',
            'granularity': 'day',
        },
        cluster_by='base64_url',
    )
}}

WITH stop_time_updates AS (
    SELECT * FROM {{ ref('fct_stop_time_updates') }}
),

fct_observed_trips AS (
    SELECT
        -- https://gtfs.org/realtime/reference/#message-tripdescriptor
        {{ dbt_utils.surrogate_key([
            'date',
            'base64_url',
            'trip_id',
            'trip_route_id',
            'trip_direction_id',
            'trip_start_time',
            'trip_start_date',
        ]) }} as key,
        date,
        base64_url,
        trip_id,
        trip_route_id,
        trip_direction_id,
        trip_start_time,
        trip_start_date,
        COUNT(DISTINCT id) AS num_distinct_message_ids,
        MIN(trip_update_timestamp) AS min_trip_update_timestamp,
        MAX(trip_update_timestamp) AS max_trip_update_timestamp,
        MAX(trip_update_delay) AS max_delay,
        COUNT(DISTINCT CASE WHEN schedule_relationship = 'SKIPPED' THEN stop_id END) AS num_skipped_stops,
    FROM stop_time_updates
    GROUP BY 1, 2, 3, 4, 5, 6, 7, 8
)

SELECT * FROM fct_observed_trips
