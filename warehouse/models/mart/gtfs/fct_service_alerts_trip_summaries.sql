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
    SELECT 
        *,
        -- per spec, start/end is +/- infinity if null: https://gtfs.org/realtime/reference/#message-timerange
        -- use placeholders instead
        COALESCE(TIMESTAMP_SECONDS(unnested_active_period.start), TIMESTAMP(DATE(1900,1,1))) AS active_period_start_ts,
        COALESCE(TIMESTAMP_SECONDS(unnested_active_period.end), TIMESTAMP(DATE(2099,1,1))) AS active_period_end_ts
    FROM {{ ref('fct_service_alerts_messages_unnested') }}
    WHERE {{ gtfs_rt_dt_where() }}
        -- TODO: support route_id/direction_id/start_time as a trip identifier
        -- as of 2023-04-20, there are no cases of service alert messages where trip ID is not populated and trip.route ID is populated
        AND trip_id IS NOT NULL
),

fct_service_alerts_trip_summaries AS (
    SELECT
        -- https://gtfs.org/realtime/reference/#message-tripdescriptor
        {{ dbt_utils.generate_surrogate_key([
            'dt',
            'base64_url',
            'trip_id',
            'trip_route_id',
            'trip_direction_id',
            'trip_start_time',
            'trip_start_date',
        ]) }} as key,
        -- TODO: once #2457 merges, we should use the schedule feed timezone rather than just Pacific
        -- we need to get individual trip instances that can be merged with schedule feed trip instances
        COALESCE(
            PARSE_DATE("%Y%m%d",trip_start_date),
            DATE(header_timestamp, "America/Los_Angeles"),
            DATE(_extract_ts, "America/Los_Angeles")) AS calculated_service_date_pacific,
        base64_url,
        trip_id,
        trip_route_id,
        trip_direction_id,
        trip_start_time,
        trip_start_date,
        COUNT(DISTINCT id) AS num_distinct_message_ids,
        COUNT(DISTINCT header_timestamp) AS num_distinct_header_timestamps,
        ARRAY_AGG(DISTINCT service_alert_message_key) AS service_alert_message_keys,
        MIN(_extract_ts) AS min_extract_ts,
        MAX(_extract_ts) AS max_extract_ts,
        MIN(header_timestamp) AS min_header_timestamp,
        MAX(header_timestamp) AS max_header_timestamp,
    FROM service_alerts
    GROUP BY 1, 2, 3, 4, 5, 6, 7, 8
)

SELECT * FROM fct_service_alerts_trip_summaries
