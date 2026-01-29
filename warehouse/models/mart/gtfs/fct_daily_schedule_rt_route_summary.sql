{{
    config(
        materialized='table',
        cluster_by=['service_date']
    )
}}

WITH schedule_trips AS (
    SELECT *
    FROM `cal-itp-data-infra-staging.tiffany_mart_gtfs.fct_scheduled_trips_testing`--{{ ref('fct_scheduled_trips') }}
),

observed_trips AS (
    SELECT *
    FROM `cal-itp-data-infra-staging.tiffany_mart_gtfs.fct_observed_trips_testing`--{{ ref('fct_observed_trips') }}
),


gtfs_join AS (
    SELECT
        schedule.service_date,
        COALESCE(schedule.base64_url, rt.schedule_base64_url) AS schedule_base64_url,
        COALESCE(schedule.name, rt.schedule_name) AS schedule_gtfs_dataset_name,
        COALESCE(schedule.gtfs_dataset_key, rt.schedule_gtfs_dataset_key) AS schedule_gtfs_dataset_key,
        schedule.trip_instance_key,

        -- Big Blue Bus has 2 different TU datasets?
        -- anyway, we need to group correctly or we overcount
        COALESCE(rt.vp_base64_url) AS vp_base64_url,
        COALESCE(rt.tu_base64_url) AS tu_base64_url,

        schedule.* EXCEPT(service_date, base64_url, name, gtfs_dataset_key, trip_instance_key),
        rt.* EXCEPT(service_date, schedule_base64_url, schedule_name, schedule_gtfs_dataset_key, trip_instance_key, vp_base64_url, tu_base64_url)


    FROM schedule_trips AS schedule
    LEFT JOIN observed_trips AS rt
        ON schedule.service_date = rt.service_date
        AND schedule.base64_url = rt.schedule_base64_url
        AND schedule.trip_instance_key = rt.trip_instance_key
),

route_direction_aggregation AS (
    SELECT
        service_date,
        schedule_base64_url,
        schedule_gtfs_dataset_name,
        schedule_gtfs_dataset_key,

        feed_key,
        vp_base64_url,
        tu_base64_url,

        COUNT(DISTINCT trip_instance_key) AS n_trips,
        route_id,
        {{ parse_route_id('schedule_gtfs_dataset_name', 'route_id') }} AS route_id_cleaned,
        {{ get_combined_route_name(
            'schedule_gtfs_dataset_name',
            'route_id', 'route_short_name', 'route_long_name'
        ) }} AS route_name,
        direction_id,
        COUNT(DISTINCT route_id) AS n_routes,

        -- slightly different than fct_observed_trips
        CASE
            WHEN COUNTIF(vp_base64_url IS NOT NULL) > 0 THEN TRUE
            ELSE FALSE
        END AS appeared_in_vp,
        CASE
            WHEN COUNTIF(tu_base64_url IS NOT NULL) > 0 THEN TRUE
            ELSE FALSE
        END AS appeared_in_tu,

        -- vehicle positions
        COALESCE(SUM(vp_num_distinct_extract_ts), 0) AS vp_num_distinct_updates,
        COALESCE(COUNTIF(vp_base64_url IS NOT NULL), 0) AS n_vp_trips,
        COALESCE(SUM(vp_extract_duration_minutes), 0) AS vp_extract_duration_minutes,
        COALESCE(ROUND(
            SAFE_DIVIDE(SUM(vp_num_distinct_extract_ts),
            SUM(vp_extract_duration_minutes)
        ), 2), 0) AS vp_messages_per_minute,


        -- trip updates
        COALESCE(SUM(tu_num_distinct_extract_ts), 0) AS tu_num_distinct_updates,
        COALESCE(COUNTIF(tu_base64_url IS NOT NULL), 0) AS n_tu_trips,
        COALESCE(SUM(tu_extract_duration_minutes), 0) AS tu_extract_duration_minutes,
        COALESCE(ROUND(
            SAFE_DIVIDE(SUM(tu_num_distinct_extract_ts),
            SUM(tu_extract_duration_minutes)
        ), 2), 0) AS tu_messages_per_minute,

    FROM gtfs_join
    GROUP BY service_date, schedule_base64_url, schedule_gtfs_dataset_name, schedule_gtfs_dataset_key, feed_key, vp_base64_url, tu_base64_url, route_id, route_id_cleaned, route_name, direction_id
),

daily_schedule_route_direction_aggregation AS (
    SELECT
        route_direction_aggregation.*,
        -- when we group, is this right way to fill missing values in for
        -- schedule trips that don't find a matching RT trip?
        -- there are still some rows that should be aggregated, but something in the quartet is missing
        -- yes schedule/yes vp/no tu is separate row from yes schedule/yes vp/yes tu
        --vp_datasets.gtfs_dataset_key AS vp_gtfs_dataset_key,
        --vp_datasets.gtfs_dataset_name AS vp_name,
        --tu_datasets.gtfs_dataset_key AS tu_gtfs_dataset_key,
        --tu_datasets.gtfs_dataset_name AS tu_name,

    FROM route_direction_aggregation
    --LEFT JOIN urls_to_datasets AS vp_datasets
    --    ON route_direction_aggregation.vp_base64_url = vp_datasets.base64_url
    --    AND route_direction_aggregation.service_date BETWEEN CAST(DATETIME(vp_datasets._valid_from, "America/Los_Angeles") AS DATE) AND CAST(DATETIME(vp_datasets._valid_to, "America/Los_Angeles") AS DATE)
    --LEFT JOIN urls_to_datasets AS tu_datasets
    --    ON route_direction_aggregation.tu_base64_url = tu_datasets.base64_url
    --    AND route_direction_aggregation.service_date BETWEEN DATETIME(tu_datasets._valid_from, "America/Los_Angeles") AND DATETIME(tu_datasets._valid_to, "America/Los_Angeles")
)

SELECT * FROM daily_schedule_route_direction_aggregation
