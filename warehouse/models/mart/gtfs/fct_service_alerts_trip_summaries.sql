{{
    config(
        materialized='table',
        cluster_by='base64_url',
    )
}}

WITH service_alerts AS (
    SELECT *
    FROM {{ ref('int_gtfs_rt__service_alerts_trip_day_map_grouping') }}
),

base_fct AS (
    {{ gtfs_rt_trip_summaries(input_table = 'service_alerts',
    urls_to_drop = '("aHR0cHM6Ly9hcGkuZ29zd2lmdC5seS9yZWFsLXRpbWUvdG9ycmFuY2UvZ3Rmcy1ydC1hbGVydHM=")') }}
),

distinct_alert_content AS (
    SELECT DISTINCT
        key,
        unnested_alert_content
    FROM service_alerts
    LEFT JOIN UNNEST(alert_content_array) AS unnested_alert_content
),

reaggregate_alert_content AS (
    SELECT
        key,
        ARRAY_AGG(
            STRUCT<message_id STRING, cause STRING, effect STRING, header STRING, description STRING >
                (JSON_VALUE(unnested_alert_content, '$.message_id'),
                JSON_VALUE(unnested_alert_content, '$.cause'),
                JSON_VALUE(unnested_alert_content, '$.effect'),
                JSON_VALUE(unnested_alert_content, '$.header'),
                JSON_VALUE(unnested_alert_content, '$.description')))
        AS alert_content_array
    FROM distinct_alert_content
    GROUP BY 1
),

fct_service_alerts_trip_summaries AS (
    SELECT
        base_fct.key,
        trip_instance_key,
        service_date,
        base64_url,
        trip_id,
        trip_start_time,
        trip_start_time_interval,
        iteration_num,
        trip_start_date,
        schedule_feed_timezone,
        schedule_base64_url,
        starting_schedule_relationship,
        ending_schedule_relationship,
        trip_route_ids,
        trip_direction_ids,
        trip_schedule_relationships,
        warning_multiple_route_ids,
        warning_multiple_direction_ids,
        COALESCE(min_header_timestamp, min_extract_ts) AS min_sa_ts,
        COALESCE(min_header_datetime_pacific, min_extract_datetime_pacific) AS min_sa_datetime_pacific,
        COALESCE(max_header_timestamp, max_extract_ts) AS max_sa_ts,
        COALESCE(max_header_datetime_pacific, max_extract_datetime_pacific) AS max_sa_datetime_pacific,
        min_extract_ts,
        max_extract_ts,
        extract_duration_minutes,
        min_extract_datetime_pacific,
        max_extract_datetime_pacific,
        min_extract_datetime_local_tz,
        max_extract_datetime_local_tz,
        min_header_timestamp,
        max_header_timestamp,
        header_duration_minutes,
        min_header_datetime_pacific,
        max_header_datetime_pacific,
        min_header_datetime_local_tz,
        max_header_datetime_local_tz,
        num_distinct_message_ids,
        num_distinct_header_timestamps,
        num_distinct_message_keys,
        num_distinct_extract_ts,
        alert_content_array,
    FROM base_fct
    LEFT JOIN reaggregate_alert_content USING (key)
)

SELECT * FROM fct_service_alerts_trip_summaries
