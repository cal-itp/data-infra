{{
    config(
        materialized='table',
        cluster_by=['service_date']
    )
}}

WITH rt_route_summary AS (
    SELECT *
    FROM {{ ref('fct_daily_schedule_rt_route_direction_summary') }}
    WHERE n_vp_trips > 0 OR n_tu_trips > 0
    -- filter to only where RT was present
    -- this table aggregates across vp_base64_url, tu_base64_url
    -- and handles the fact that trips may not have both tu and vp
    -- but we want to see the quartet together
),

summarize_service AS (
    SELECT
        service_date,
        schedule_base64_url,
        schedule_gtfs_dataset_name,
        schedule_gtfs_dataset_key,
        feed_key,

        tu_gtfs_dataset_key,
        tu_name,
        tu_base64_url,
        vp_gtfs_dataset_key,
        vp_name,
        vp_base64_url,

        SUM(n_trips) AS n_trips,
        COUNT(DISTINCT route_id) AS n_routes,

        LOGICAL_OR(appeared_in_tu) AS appeared_in_tu,
        LOGICAL_OR(appeared_in_vp) AS appeared_in_vp,

        -- trip updates
        SUM(tu_num_distinct_updates) AS tu_num_distinct_updates,
        SUM(n_tu_trips) AS n_tu_trips,
        COUNT(DISTINCT IF(appeared_in_tu IS TRUE, route_id, NULL)) AS n_tu_routes,
        SUM(tu_extract_duration_minutes) AS tu_extract_duration_minutes,
        ROUND(
            SAFE_DIVIDE(SUM(tu_num_distinct_updates),
            SUM(tu_extract_duration_minutes)
        ), 2) AS tu_messages_per_minute,

        -- vehicle positions
        SUM(vp_num_distinct_updates) AS vp_num_distinct_updates,
        SUM(n_vp_trips) AS n_vp_trips,
        COUNT(DISTINCT IF(appeared_in_vp IS TRUE, route_id, NULL)) AS n_vp_routes,
        SUM(vp_extract_duration_minutes) AS vp_extract_duration_minutes,
        ROUND(
            SAFE_DIVIDE(SUM(vp_num_distinct_updates),
            SUM(vp_extract_duration_minutes)
        ), 2) AS vp_messages_per_minute,

    FROM rt_route_summary
    GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11
)

SELECT * FROM summarize_service
