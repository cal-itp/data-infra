{{
    config(
        materialized='table',
        cluster_by=['service_date']
    )
}}

WITH schedule_trips AS (
    SELECT * FROM {{ ref('fct_scheduled_trips') }}
),

observed_trips AS (
    SELECT * FROM {{ ref('fct_observed_trips') }}
),

-- add this to make sure we correctly link quartets
dim_provider_gtfs_data AS (
    SELECT
        schedule_gtfs_dataset_key,
        vehicle_positions_gtfs_dataset_key,
        trip_updates_gtfs_dataset_key
    FROM {{ ref('dim_provider_gtfs_data') }}
    GROUP BY 1, 2, 3
),

gtfs_join AS (
    SELECT
        schedule.service_date,
        COALESCE(schedule.base64_url, rt.schedule_base64_url) AS schedule_base64_url,
        COALESCE(schedule.name, rt.schedule_name) AS schedule_gtfs_dataset_name,
        COALESCE(schedule.gtfs_dataset_key, rt.schedule_gtfs_dataset_key) AS schedule_gtfs_dataset_key,
        schedule.trip_instance_key,

        schedule.* EXCEPT(service_date, base64_url, name, gtfs_dataset_key, trip_instance_key),
        rt.* EXCEPT(service_date, schedule_base64_url, schedule_name, schedule_gtfs_dataset_key, trip_instance_key),
        {{ generate_time_of_day_hours('time_of_day') }} AS n_hours,

    FROM schedule_trips AS schedule
    LEFT JOIN observed_trips AS rt
        ON schedule.service_date = rt.service_date
        AND schedule.base64_url = rt.schedule_base64_url
        AND schedule.trip_instance_key = rt.trip_instance_key
),

time_of_day_counts AS (
    SELECT
        service_date,
        schedule_gtfs_dataset_key,
        time_of_day,
        route_id,
        direction_id,

        COUNT(DISTINCT trip_instance_key) AS n_trips,
        MAX(n_hours) AS n_hours,
    FROM gtfs_join
    GROUP BY 1, 2, 3, 4, 5
),

pivoted_timeofday AS (
    SELECT *
    FROM (
        SELECT
            schedule_gtfs_dataset_key,
            service_date,
            route_id,
            direction_id,

            time_of_day,
            n_trips,
            n_hours
        FROM time_of_day_counts
    )
    PIVOT(
        MIN(n_trips) AS trips,
        MIN(n_trips / n_hours) AS frequency
        FOR time_of_day IN
        ("owl", "early_am", "am_peak", "midday", "pm_peak", "evening")
    )
),

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
        route_type,

        COUNT(DISTINCT trip_instance_key) AS n_trips,
        COUNT(DISTINCT route_id) AS n_routes,
        COUNT(DISTINCT shape_id) AS n_shapes,
        ROUND(AVG(num_distinct_stops_served), 1) AS avg_stops_served,
        SUM(num_stop_times) AS num_stop_times,
        COALESCE(ROUND(SUM(service_hours), 2), 0) AS service_hours,
        COALESCE(ROUND(SUM(flex_service_hours), 2), 0) AS flex_service_hours,
    FROM gtfs_join
    GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10
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
        route_id,
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
    GROUP BY 1, 2, 3, 4, 5, 6, 7, 8
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
        route_id,
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
    GROUP BY 1, 2, 3, 4, 5, 6, 7, 8
),

schedule_with_quartet AS (
    SELECT
        schedule_aggregation.*,
        dim_provider_gtfs_data.trip_updates_gtfs_dataset_key,
        dim_provider_gtfs_data.vehicle_positions_gtfs_dataset_key,
    FROM schedule_aggregation
    INNER JOIN dim_provider_gtfs_data USING (schedule_gtfs_dataset_key)
),

route_direction_aggregation AS (
    SELECT
        schedule.service_date,
        schedule.schedule_base64_url,
        schedule.schedule_gtfs_dataset_name AS schedule_name,
        schedule.schedule_gtfs_dataset_key,
        schedule.feed_key,

        schedule.route_id,
        schedule.route_id_cleaned,
        schedule.route_name,
        schedule.direction_id,
        schedule.route_type,

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

        -- from pivoted
        COALESCE(trips_owl, 0) AS daily_trips_owl,
		COALESCE(trips_early_am, 0) AS daily_trips_early_am,
		COALESCE(trips_am_peak, 0) AS daily_trips_am_peak,
		COALESCE(trips_midday, 0) AS daily_trips_midday,
		COALESCE(trips_pm_peak, 0) AS daily_trips_pm_peak,
		COALESCE(trips_evening, 0) AS daily_trips_evening,
		COALESCE(trips_am_peak, 0) + COALESCE(trips_pm_peak, 0) AS daily_trips_peak,
		n_trips - (COALESCE(trips_am_peak, 0) + COALESCE(trips_pm_peak, 0)) AS daily_trips_offpeak,

		COALESCE(ROUND(frequency_owl, 2), 0) AS frequency_owl,
		COALESCE(ROUND(frequency_early_am, 2), 0) AS frequency_early_am,
		COALESCE(ROUND(frequency_am_peak, 2), 0) AS frequency_am_peak,
		COALESCE(ROUND(frequency_midday, 2), 0) AS frequency_midday,
		COALESCE(ROUND(frequency_pm_peak, 2), 0) AS frequency_pm_peak,
		COALESCE(ROUND(frequency_evening, 2), 0) AS frequency_evening,

        -- calculate frequency for peak/offpeak this way by weighting the hours present in each category, add frequency for all_day
		ROUND(
			(COALESCE(frequency_am_peak, 0) * 3 + COALESCE(frequency_pm_peak, 0) * 5) / 8,
		2) AS frequency_peak,
		ROUND(
			(COALESCE(frequency_owl, 0) * 4 + COALESCE(frequency_early_am, 0) * 3
			+ COALESCE(frequency_midday, 0) * 5 + COALESCE(frequency_evening, 0) * 4) / 16,
		2) AS frequency_offpeak,
        ROUND(n_trips / 24) AS frequency_all_day,

        -- follow pattern in fct_observed_trips
        tu_base64_url IS NOT NULL AS appeared_in_tu,
        vp_base64_url IS NOT NULL AS appeared_in_vp,

        -- add this to detect rows that are nulls that are double counting schedule data
        COUNT(tu_base64_url) OVER(
            PARTITION BY schedule.service_date, schedule_gtfs_dataset_name, schedule.route_id, schedule.direction_id
        ) AS has_tu,
        COUNT(vp_base64_url) OVER(
            PARTITION BY schedule.service_date, schedule_gtfs_dataset_name, schedule.route_id, schedule.direction_id
        ) AS has_vp,

        -- vehicle positions
        vp.vp_num_distinct_updates,
        vp.n_vp_trips,
        vp.vp_extract_duration_minutes,
        vp.vp_messages_per_minute,

        -- trip updates
        tu.tu_num_distinct_updates,
        tu.n_tu_trips,
        tu.tu_extract_duration_minutes,
        tu.tu_messages_per_minute,

    FROM schedule_with_quartet AS schedule
    INNER JOIN pivoted_timeofday AS pivoted
        ON schedule.service_date = pivoted.service_date
        AND schedule.schedule_gtfs_dataset_key = pivoted.schedule_gtfs_dataset_key
        AND schedule.route_id = pivoted.route_id
        AND COALESCE(schedule.direction_id, -1) = COALESCE(pivoted.direction_id, -1)
    LEFT JOIN tu_aggregation AS tu
        ON schedule.service_date = tu.service_date
        AND schedule.schedule_base64_url = tu.schedule_base64_url
        AND schedule.trip_updates_gtfs_dataset_key = tu.tu_gtfs_dataset_key
        AND schedule.route_name = tu.route_name
        AND COALESCE(schedule.direction_id, -1) = COALESCE(tu.direction_id, -1)
    LEFT JOIN vp_aggregation AS vp
        ON schedule.service_date = vp.service_date
        AND schedule.schedule_base64_url = vp.schedule_base64_url
		AND schedule.vehicle_positions_gtfs_dataset_key = vp.vp_gtfs_dataset_key
        AND schedule.route_name = vp.route_name
        AND COALESCE(schedule.direction_id, -1) = COALESCE(vp.direction_id, -1)
    WHERE n_trips > 0
),

route_direction_aggregation2 AS (
    SELECT
        * EXCEPT(has_vp, has_tu)
    FROM route_direction_aggregation
    -- distinguish between rows that have no RT for that operator at all vs
    -- particular row didn't have RT for that route-dir combo but had RT observed that day
    -- for a day, there can be several combos from the left join:
    -- day1  schedule1  no_tu_route_dir  yes_vp_route_dir
    -- day1  schedule1  yes_tu_route_dir yes_vp_route_dir
    -- day1  schedule1  no_tu_route_dir  no_vp_route_dir (drop row)
    -- day1  schedule2  no_tu_route_dir  no_vp_route_dir (keep row)
    WHERE (appeared_in_tu AND has_tu >= 1) OR (appeared_in_vp AND has_vp >= 1)
)

SELECT * FROM route_direction_aggregation2
