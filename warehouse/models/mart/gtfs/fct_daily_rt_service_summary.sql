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

-- for a day, there can be several combos:
-- day1  schedule  no_tu_route_dir  yes_vp_route_dir
-- day1  schedule  yes_tu_route_dir yes_vp_route_dir
-- these will appear as different rows. for a given day, we want the
-- sums of all available tu rows and all available vp rows
tu_aggregation AS (
    SELECT
        service_date,
        schedule_gtfs_dataset_key,

        tu_base64_url,
        tu_name,
        tu_gtfs_dataset_key,

        -- trip updates
        SUM(tu_num_distinct_updates) AS tu_num_distinct_updates,
        SUM(n_tu_trips) AS n_tu_trips,
        COUNT(DISTINCT IF(appeared_in_tu IS TRUE, route_id, NULL)) AS n_tu_routes,
        SUM(tu_extract_duration_minutes) AS tu_extract_duration_minutes,
        ROUND(
            SAFE_DIVIDE(SUM(tu_num_distinct_updates),
            SUM(tu_extract_duration_minutes)
        ), 2) AS tu_messages_per_minute,
    FROM rt_route_summary
    WHERE appeared_in_tu
    GROUP BY 1, 2, 3, 4, 5
),

vp_aggregation AS (
    SELECT
        service_date,
        schedule_gtfs_dataset_key,

        vp_gtfs_dataset_key,
        vp_name,
        vp_base64_url,
        -- add this to make sure the tu belonging to quartet is linked and use in join
        -- schedule can be linked to 2 RT feeds (Marin temporarily), and
        -- the quartet gets scrambled. combinations will incorrectly
        -- Marin Optibus - Equans VP - Swiftly TU
        -- Marin Optibus - Swiftly VP - Equans TU

        MAX(tu_gtfs_dataset_key) AS tu_gtfs_dataset_key,

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
    WHERE appeared_in_vp
    GROUP BY 1, 2, 3, 4, 5
),

schedule_aggregation AS (
    SELECT
        service_date,
        schedule_base64_url,
        schedule_name,
        schedule_gtfs_dataset_key,
        feed_key,

        SUM(n_trips) AS n_trips,
        COUNT(DISTINCT route_id) AS n_routes,

        LOGICAL_OR(appeared_in_tu) AS appeared_in_tu,
        LOGICAL_OR(appeared_in_vp) AS appeared_in_vp,
    FROM rt_route_summary
    GROUP BY 1, 2, 3, 4, 5
),

summarize_service AS (
    SELECT
        schedule.service_date,
        schedule.schedule_base64_url,
        schedule.schedule_name,
        schedule.schedule_gtfs_dataset_key,
        schedule.feed_key,

        tu.tu_base64_url,
        tu.tu_name,
        tu.tu_gtfs_dataset_key,
        vp.vp_gtfs_dataset_key,
        vp.vp_name,
        vp.vp_base64_url,

        schedule.n_trips,
        schedule.n_routes,
        schedule.appeared_in_tu,
        schedule.appeared_in_vp,

        -- trip updates
        tu.tu_num_distinct_updates,
        tu.n_tu_trips,
        tu.n_tu_routes,
        tu.tu_extract_duration_minutes,
        tu.tu_messages_per_minute,

        -- vehicle positions
        vp.vp_num_distinct_updates,
        vp.n_vp_trips,
        vp.n_vp_routes,
        vp.vp_extract_duration_minutes,
        vp.vp_messages_per_minute,

    FROM schedule_aggregation AS schedule
    LEFT JOIN tu_aggregation AS tu
        USING (service_date, schedule_gtfs_dataset_key)
    LEFT JOIN vp_aggregation AS vp
         USING (service_date, schedule_gtfs_dataset_key, tu_gtfs_dataset_key)
)

SELECT * FROM summarize_service
