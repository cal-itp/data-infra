{{
    config(
        materialized='incremental',
        incremental_strategy='insert_overwrite',
        partition_by={
            'field': 'calculated_service_date_pacific',
            'data_type': 'date',
            'granularity': 'day',
        },
        cluster_by='base64_url',
    )
}}

WITH stop_time_updates AS (
    SELECT *
    FROM {{ ref('fct_stop_time_updates') }}
    WHERE {{ gtfs_rt_dt_where(this_dt_column = 'calculated_service_date_pacific') }}
),

fct_trip_updates_summaries AS (
    SELECT
        -- https://gtfs.org/realtime/reference/#message-tripdescriptor
        {{ dbt_utils.generate_surrogate_key([
            'calculated_service_date_pacific',
            'base64_url',
            'trip_id',
            'trip_route_id',
            'trip_direction_id',
            'trip_start_time',
            'trip_start_date',
        ]) }} as key,

        calculated_service_date_pacific,
        base64_url,
        trip_id,
        trip_route_id,
        trip_direction_id,
        trip_start_time,
        trip_start_date,
        COUNT(DISTINCT id) AS num_distinct_message_ids,
        COUNT(DISTINCT header_timestamp) AS num_distinct_header_timestamps,
        COUNT(DISTINCT trip_update_timestamp) AS num_distinct_trip_update_timestamps,
        MIN(_extract_ts) AS min_extract_ts,
        MAX(_extract_ts) AS max_extract_ts,
        MIN(header_timestamp) AS min_header_timestamp,
        MAX(header_timestamp) AS max_header_timestamp,
        MIN(trip_update_timestamp) AS min_trip_update_timestamp,
        MAX(trip_update_timestamp) AS max_trip_update_timestamp,
        MAX(trip_update_delay) AS max_delay,
        COUNT(DISTINCT CASE WHEN schedule_relationship = 'SKIPPED' THEN stop_id END) AS num_skipped_stops,
        COUNT(DISTINCT CASE WHEN schedule_relationship IN ('SCHEDULED', 'CANCELED', 'ADDED') THEN stop_id END) AS num_scheduled_canceled_added_stops,
    FROM stop_time_updates
    GROUP BY 1, 2, 3, 4, 5, 6, 7, 8
)

SELECT * FROM fct_trip_updates_summaries
