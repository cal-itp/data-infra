{{
    config(
        materialized='incremental',
        incremental_strategy='insert_overwrite',
        partition_by={
            'field': 'dt',
            'data_type': 'date',
            'granularity': 'day',
        },
        cluster_by='base64_url',
    )
}}

WITH stop_time_updates AS (
    SELECT *
    FROM {{ ref('fct_stop_time_updates') }}
    WHERE dt >= '2024-01-01' AND dt <= '2024-01-02'
),

-- group by *both* the UTC date that data was scraped (dt) *and* calculated service date
-- so that in the mart we can get just service date-level data
-- this allows us to handle the dt/service_date mismatch by grouping in two stages
grouped AS (
    SELECT
        dt,
        service_date,
        base64_url,
        trip_id,
        trip_route_id,
        trip_direction_id,
        trip_start_time,
        trip_schedule_relationship,
        schedule_feed_timezone,
        schedule_base64_url,
        trip_start_time_interval,
        MIN(trip_start_date) AS trip_start_date,
        ARRAY_AGG(DISTINCT id) AS message_ids_array,
        ARRAY_AGG(DISTINCT header_timestamp) AS header_timestamps_array,
        ARRAY_AGG(DISTINCT trip_update_timestamp IGNORE NULLS) AS trip_update_timestamps_array,
        ARRAY_AGG(DISTINCT _trip_updates_message_key) AS message_keys_array,
        ARRAY_AGG(DISTINCT _extract_ts) AS extract_ts_array,
        MIN(_extract_ts) AS min_extract_ts,
        MAX(_extract_ts) AS max_extract_ts,
        MIN(header_timestamp) AS min_header_timestamp,
        MAX(header_timestamp) AS max_header_timestamp,
        MIN(trip_update_timestamp) AS min_trip_update_timestamp,
        MAX(trip_update_timestamp) AS max_trip_update_timestamp,
        MAX(trip_update_delay) AS max_delay,
        ARRAY_AGG(DISTINCT CASE WHEN schedule_relationship = 'SKIPPED' THEN stop_id END IGNORE NULLS) AS skipped_stops_array,
        ARRAY_AGG(DISTINCT CASE WHEN schedule_relationship = 'SCHEDULED' THEN stop_id END IGNORE NULLS) AS scheduled_stops_array,
        ARRAY_AGG(DISTINCT CASE WHEN schedule_relationship = 'CANCELED' THEN stop_id END IGNORE NULLS) AS canceled_stops_array,
        ARRAY_AGG(DISTINCT CASE WHEN schedule_relationship = 'ADDED' THEN stop_id END IGNORE NULLS) AS added_stops_array,
    FROM stop_time_updates
    WHERE trip_id IS NOT NULL
    GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11
),

int_gtfs_rt__trip_updates_trip_day_map_grouping AS (
    SELECT
        -- https://gtfs.org/realtime/reference/#message-tripdescriptor
        -- this key is not unique yet here but will be on the downstream final model
        {{ dbt_utils.generate_surrogate_key([
            'service_date',
            'base64_url',
            'schedule_base64_url',
            'trip_id',
            'trip_start_time',
        ]) }} as key,
        dt,
        service_date,
        base64_url,
        trip_id,
        trip_route_id,
        trip_direction_id,
        trip_start_time,
        trip_start_time_interval,
        trip_start_date,
        trip_schedule_relationship,
        schedule_feed_timezone,
        schedule_base64_url,
        message_ids_array,
        header_timestamps_array,
        trip_update_timestamps_array,
        message_keys_array,
        extract_ts_array,
        min_extract_ts,
        max_extract_ts,
        min_header_timestamp,
        max_header_timestamp,
        min_trip_update_timestamp,
        max_trip_update_timestamp,
        max_delay,
        skipped_stops_array,
        scheduled_stops_array,
        canceled_stops_array,
        added_stops_array,
    FROM grouped
)

SELECT * FROM int_gtfs_rt__trip_updates_trip_day_map_grouping
