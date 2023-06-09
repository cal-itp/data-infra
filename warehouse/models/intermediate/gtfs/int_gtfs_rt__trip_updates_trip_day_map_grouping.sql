{{
    config(
        materialized='incremental',
        incremental_strategy='insert_overwrite',
        partition_by={
            'field': 'calculated_service_date',
            'data_type': 'date',
            'granularity': 'day',
        },
        cluster_by='base64_url',
    )
}}

WITH stop_time_updates AS (
    SELECT *
    FROM {{ ref('fct_stop_time_updates') }}
    WHERE {{ gtfs_rt_dt_where() }}
),

rt_feeds AS (
    SELECT *
    FROM {{ ref('fct_daily_rt_feed_files') }}
),

schedule_feeds AS (
    SELECT *
    FROM {{ ref('dim_schedule_feeds') }}
),

-- group by *both* the UTC date that data was scraped (dt) *and* calculated service date
-- so that in the mart we can get just service date-level data
-- this allows us to handle the dt/service_date mismatch by grouping in two stages
int_gtfs_rt__trip_updates_trip_day_map_grouping AS (
    SELECT
        -- try to figure out what the service date would be to join back with schedule: fall back from explicit to imputed
        -- TODO: it's possible that this could lead to some weirdness around midnight Pacific / in feed timezone
        -- if `trip_start_date` is not set we theoretically should be trying to grab the date of the first arrival time per trip
        -- because trip updates may be generated hours before the beginning of the actual trip activity
        -- however the fact that this would occur near date boundaries is precisely why it's a bit tricky to pick the right first arrival time if trip start date is not populated
        dt,
        COALESCE(
            PARSE_DATE("%Y%m%d", trip_start_date),
            DATE(header_timestamp, schedule_feeds.feed_timezone),
            DATE(_extract_ts, schedule_feeds.feed_timezone)) AS calculated_service_date,
        stop_time_updates.base64_url,
        trip_id,
        trip_route_id,
        trip_direction_id,
        trip_start_time,
        trip_start_date,
        trip_schedule_relationship,
        schedule_feeds.feed_timezone,
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
    LEFT JOIN rt_feeds
        ON stop_time_updates.base64_url = rt_feeds.base64_url
        AND stop_time_updates.dt = rt_feeds.date
    LEFT JOIN schedule_feeds
        ON rt_feeds.schedule_feed_key = schedule_feeds.key
    GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10
)

SELECT * FROM int_gtfs_rt__trip_updates_trip_day_map_grouping
