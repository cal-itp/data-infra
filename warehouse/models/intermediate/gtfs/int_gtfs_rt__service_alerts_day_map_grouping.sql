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

WITH service_alerts AS (
    SELECT *
    FROM {{ ref('fct_service_alerts_messages_unnested') }}
    WHERE {{ incremental_where(default_start_var='PROD_GTFS_RT_START') }}
),

-- group by *both* the UTC date that data was scraped (dt) *and* calculated local active date
-- so that in the mart we can get just active date-level data
-- this allows us to handle the dt/active_date mismatch by grouping in two stages
grouped AS (
    SELECT
        dt,
        COALESCE(
            DATE(header_timestamp, schedule_feed_timezone),
            DATE(_extract_ts, schedule_feed_timezone)) AS active_date,
        base64_url,
        schedule_feed_timezone,
        id,
        cause,
        effect,
        header_text_text AS header,
        description_text_text AS description,
        trip_id,
        trip_route_id,
        trip_direction_id,
        trip_start_time,
        trip_start_date,
        trip_schedule_relationship,
        agency_id,
        route_id,
        route_type,
        direction_id,
        stop_id,
        active_period_start,
        active_period_end,
        active_period_start_ts,
        active_period_end_ts,
        ARRAY_AGG(DISTINCT _extract_ts) AS extract_ts_array,
        ARRAY_AGG(DISTINCT header_timestamp) AS header_timestamps_array,
        ARRAY_AGG(DISTINCT service_alert_message_key) AS message_keys_array,
        MIN(_extract_ts) AS min_extract_ts,
        MAX(_extract_ts) AS max_extract_ts,
        MIN(header_timestamp) AS min_header_timestamp,
        MAX(header_timestamp) AS max_header_timestamp
    FROM service_alerts
    WHERE header_timestamp BETWEEN active_period_start_ts AND active_period_end_ts
    GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24
),

int_gtfs_rt__service_alerts_day_map_grouping AS (
    SELECT
        -- we shouldn't need header and description here (those should be distinguished by id) but there seem to be cases where id is not unique
        {{ dbt_utils.generate_surrogate_key([
            'active_date',
            'base64_url',
            'id',
            'header',
            'description',
            'active_period_start',
            'active_period_end',
            'agency_id',
            'route_id',
            'trip_id',
            'stop_id'
        ]) }} as key,
        dt,
        active_date,
        base64_url,
        schedule_feed_timezone,
        id,
        cause,
        effect,
        header,
        description,
        trip_id,
        trip_route_id,
        trip_direction_id,
        trip_start_time,
        trip_start_date,
        trip_schedule_relationship,
        agency_id,
        route_id,
        route_type,
        direction_id,
        stop_id,
        active_period_start,
        active_period_end,
        active_period_start_ts,
        active_period_end_ts,
        extract_ts_array,
        header_timestamps_array,
        message_keys_array,
        min_extract_ts,
        max_extract_ts,
        min_header_timestamp,
        max_header_timestamp
    FROM grouped
)

SELECT * FROM int_gtfs_rt__service_alerts_day_map_grouping
