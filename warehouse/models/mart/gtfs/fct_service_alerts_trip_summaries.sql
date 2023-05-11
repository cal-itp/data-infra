{{
    config(
        materialized='table',
        cluster_by='base64_url',
    )
}}


WITH service_alerts AS (
    SELECT * FROM {{ ref('int_gtfs_rt__service_alerts_trip_day_map_grouping') }}
),

fct_service_alerts_trip_summaries AS (
    SELECT
        -- https://gtfs.org/realtime/reference/#message-tripdescriptor
        {{ dbt_utils.generate_surrogate_key([
            'calculated_service_date',
            'base64_url',
            'trip_id',
            'trip_start_time',
        ]) }} as key,
        calculated_service_date,
        base64_url,
        trip_id,
        trip_route_id,
        trip_direction_id,
        trip_start_time,
        trip_start_date,
        trip_schedule_relationship,
        feed_timezone,
        COUNT(DISTINCT unnested_message_ids) AS num_distinct_message_ids,
        COUNT(DISTINCT unested_header_timestamps) AS num_distinct_header_timestamps,
        COUNT(DISTINCT unnested_message_keys) AS num_distinct_message_keys,
        MIN(min_extract_ts) AS min_extract_ts,
        MAX(max_extract_ts) AS max_extract_ts,
        MIN(min_header_timestamp) AS min_header_timestamp,
        MAX(max_header_timestamp) AS max_header_timestamp
    FROM service_alerts
    LEFT JOIN UNNEST(message_ids_array) AS unnested_message_ids
    LEFT JOIN UNNEST(header_timestamps_array) AS unested_header_timestamps
    LEFT JOIN UNNEST(message_keys_array) AS unnested_message_keys
    GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10
)

SELECT * FROM fct_service_alerts_trip_summaries
