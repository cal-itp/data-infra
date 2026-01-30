{{
    config(
        materialized='table',
        cluster_by=['service_date']
    )
}}

WITH schedule_trips AS (
    SELECT *
    FROM {{ ref('fct_scheduled_trips') }}
),

observed_trips AS (
    SELECT *
    FROM {{ ref('fct_observed_trips') }}
),


gtfs_join AS (
    SELECT
        schedule.service_date,
        COALESCE(schedule.base64_url, rt.schedule_base64_url) AS schedule_base64_url,
        COALESCE(schedule.name, rt.schedule_name) AS schedule_gtfs_dataset_name,
        COALESCE(schedule.gtfs_dataset_key, rt.schedule_gtfs_dataset_key) AS schedule_gtfs_dataset_key,
        schedule.trip_instance_key,

        schedule.* EXCEPT(service_date, base64_url, name, gtfs_dataset_key, trip_instance_key),
        rt.* EXCEPT(service_date, schedule_base64_url, schedule_name, schedule_gtfs_dataset_key, trip_instance_key)

    FROM schedule_trips AS schedule
    LEFT JOIN observed_trips AS rt
        ON schedule.service_date = rt.service_date
        AND schedule.base64_url = rt.schedule_base64_url
        AND schedule.trip_instance_key = rt.trip_instance_key
),

-- group these separately so that we don't have values where it's these combos exist:
-- schedule/vp/no_tu, schedule/no_vp/tu, schedule/no_vp/no_tu, schedule/vp/tu
schedule_aggregation AS (
    SELECT
        service_date,
        schedule_base64_url,
        schedule_gtfs_dataset_name,
        schedule_gtfs_dataset_key,
        feed_key,

        route_id,
        {{ parse_route_id('schedule_gtfs_dataset_name', 'route_id') }} AS route_id_cleaned,
        {{ get_combined_route_name(
            'schedule_gtfs_dataset_name',
            'route_id', 'route_short_name', 'route_long_name'
        ) }} AS route_name,
        direction_id,

        COUNT(DISTINCT trip_instance_key) AS n_trips,
        COUNT(DISTINCT route_id) AS n_routes,
        COUNT(DISTINCT shape_id) AS n_shapes,
        ROUND(AVG(num_distinct_stops_served), 1) AS avg_stops_served,
        SUM(num_stop_times) AS num_stop_times,
        COALESCE(ROUND(SUM(service_hours), 2), 0) AS service_hours,
        COALESCE(ROUND(SUM(flex_service_hours), 2), 0) AS flex_service_hours,

    FROM gtfs_join
    GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9
),

tu_aggregation AS (
    SELECT
        service_date,
        schedule_base64_url,
        tu_base64_url,
        tu_name,
        tu_gtfs_dataset_key,

        {{ get_combined_route_name(
            'schedule_gtfs_dataset_name',
            'route_id', 'route_short_name', 'route_long_name'
        ) }} AS route_name,
        direction_id,

        -- trip updates
        COALESCE(SUM(tu_num_distinct_extract_ts), 0) AS tu_num_distinct_updates,
        COUNT(*) AS n_tu_trips,
        COALESCE(SUM(tu_extract_duration_minutes), 0) AS tu_extract_duration_minutes,
        COALESCE(ROUND(
            SAFE_DIVIDE(SUM(tu_num_distinct_extract_ts),
            SUM(tu_extract_duration_minutes)
        ), 2), 0) AS tu_messages_per_minute,
    FROM gtfs_join
    WHERE tu_base64_url IS NOT NULL
    GROUP BY 1, 2, 3, 4, 5, 6, 7
),

vp_aggregation AS (
    SELECT
        service_date,
        schedule_base64_url,
        vp_base64_url,
        vp_name,
        vp_gtfs_dataset_key,

        {{ get_combined_route_name(
            'schedule_gtfs_dataset_name',
            'route_id', 'route_short_name', 'route_long_name'
        ) }} AS route_name,
        direction_id,

        -- vehicle positions
        COALESCE(SUM(vp_num_distinct_extract_ts), 0) AS vp_num_distinct_updates,
        COUNT(*) AS n_vp_trips,
        COALESCE(SUM(vp_extract_duration_minutes), 0) AS vp_extract_duration_minutes,
        COALESCE(ROUND(
            SAFE_DIVIDE(SUM(vp_num_distinct_extract_ts),
            SUM(vp_extract_duration_minutes)
        ), 2), 0) AS vp_messages_per_minute,
    FROM gtfs_join
    WHERE vp_base64_url IS NOT NULL
    GROUP BY 1, 2, 3, 4, 5, 6, 7
),


route_direction_aggregation AS (
    SELECT
        schedule.service_date,
        schedule.schedule_base64_url,
        schedule.schedule_gtfs_dataset_name,
        schedule.schedule_gtfs_dataset_key,
        schedule.feed_key,

        schedule.route_id,
        schedule.route_id_cleaned,
        schedule.route_name,
        schedule.direction_id,

        tu.tu_gtfs_dataset_key,
        tu.tu_name,
        tu.tu_base64_url,
        vp.vp_gtfs_dataset_key,
        vp.vp_name,
        vp.vp_base64_url,

        schedule.n_trips,
        schedule.n_routes,
        schedule.n_shapes,
        schedule.avg_stops_served,
        schedule.num_stop_times,
        schedule.service_hours,
        schedule.flex_service_hours,

        -- follow pattern in fct_observed_trips
        tu_base64_url IS NOT NULL AS appeared_in_tu,
        vp_base64_url IS NOT NULL AS appeared_in_vp,

        -- vehicle positions
        vp.vp_num_distinct_updates,
        vp.n_vp_trips,
        vp.vp_extract_duration_minutes,
        vp.vp_messages_per_minute,
        ROUND(
            SAFE_DIVIDE(vp_extract_duration_minutes,
            (service_hours + flex_service_hours) * 60),
        3) AS pct_vp_service_hours,

        -- trip updates
        tu.tu_num_distinct_updates,
        tu.n_tu_trips,
        tu.tu_extract_duration_minutes,
        tu.tu_messages_per_minute,
        ROUND(
            SAFE_DIVIDE(
                tu_extract_duration_minutes,
                (service_hours + flex_service_hours) * 60),
        3) AS pct_tu_service_hours,

    FROM schedule_aggregation AS schedule
    LEFT JOIN tu_aggregation AS tu
        ON schedule.service_date = tu.service_date
        AND schedule.schedule_base64_url = tu.schedule_base64_url
        AND schedule.route_name = tu.route_name
        AND COALESCE(schedule.direction_id, -1) = COALESCE(tu.direction_id, -1)
    LEFT JOIN vp_aggregation AS vp
        ON schedule.service_date = vp.service_date
        AND schedule.schedule_base64_url = vp.schedule_base64_url
        AND schedule.route_name = vp.route_name
        AND COALESCE(schedule.direction_id, -1) = COALESCE(vp.direction_id, -1)
    WHERE n_trips > 0 AND (n_vp_trips > 0 OR n_tu_trips > 0)
)

SELECT * FROM route_direction_aggregation
