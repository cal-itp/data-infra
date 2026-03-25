{{ config(materialized='table') }}

WITH daily_summary AS (
    SELECT *
    FROM {{ ref('fct_daily_schedule_rt_route_direction_summary') }}
),

route_direction_aggregation AS (
    SELECT
        EXTRACT(month FROM service_date) AS month,
        EXTRACT(year FROM service_date) AS year,
        DATE_TRUNC(service_date, MONTH) AS month_first_day,
        {{ generate_day_type('service_date') }} AS day_type,
        schedule_base64_url,
        schedule_name,
        tu_base64_url,
        tu_name, -- can there be different tu_base64_urls across a month? probably, and tu_name would change then
        vp_base64_url,
        vp_name,
        route_name,
        direction_id,
        MAX(route_type) AS route_type,

        -- schedule
        SUM(n_trips) AS n_trips,
		ROUND(AVG(n_trips), 2) AS daily_trips_all_day,
        COUNT(DISTINCT route_id) AS n_route_ids,
        ROUND(AVG(n_shapes), 1) AS n_shapes,
        ROUND(AVG(avg_stops_served), 1) AS avg_stops_served,
        COUNT(DISTINCT feed_key) AS n_feeds,
        COUNT(DISTINCT service_date) AS n_days,

        ROUND(AVG(daily_trips_owl), 2) AS daily_trips_owl,
		ROUND(AVG(daily_trips_early_am), 2) AS daily_trips_early_am,
		ROUND(AVG(daily_trips_am_peak), 2) AS daily_trips_am_peak,
		ROUND(AVG(daily_trips_midday), 2) AS daily_trips_midday,
		ROUND(AVG(daily_trips_pm_peak), 2) AS daily_trips_pm_peak,
		ROUND(AVG(daily_trips_evening), 2) AS daily_trips_evening,
		ROUND(AVG(daily_trips_peak), 2) AS daily_trips_peak,
		ROUND(AVG(daily_trips_offpeak), 2) AS daily_trips_offpeak,

		ROUND(AVG(frequency_owl), 2) AS frequency_owl,
		ROUND(AVG(frequency_early_am), 2) AS frequency_early_am,
		ROUND(AVG(frequency_am_peak), 2) AS frequency_am_peak,
		ROUND(AVG(frequency_midday), 2) AS frequency_midday,
		ROUND(AVG(frequency_pm_peak), 2) AS frequency_pm_peak,
		ROUND(AVG(frequency_evening), 2) AS frequency_evening,
		ROUND(AVG(frequency_peak), 2) AS frequency_peak,
		ROUND(AVG(frequency_offpeak), 2) AS frequency_offpeak,
		ROUND(AVG(frequency_all_day), 2) AS frequency_all_day,

        LOGICAL_OR(appeared_in_tu) AS appeared_in_tu,
        LOGICAL_OR(appeared_in_vp) AS appeared_in_vp,

        -- vehicle positions
        SUM(vp_num_distinct_updates) AS vp_num_distinct_updates,
        SUM(n_vp_trips) AS n_vp_trips,
        SUM(vp_extract_duration_minutes) AS vp_extract_duration_minutes,
        ROUND(AVG(vp_messages_per_minute), 1) AS vp_messages_per_minute,

        -- trip updates
        SUM(tu_num_distinct_updates) AS tu_num_distinct_updates,
        SUM(n_tu_trips) AS n_tu_trips,
        SUM(tu_extract_duration_minutes) AS tu_extract_duration_minutes,
        ROUND(AVG(tu_messages_per_minute), 1) AS tu_messages_per_minute,

    FROM daily_summary
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12
),

route_direction_aggregation_with_typology AS (
    SELECT
        *,
        -- get what we can based on route name to separate our bus types
        -- https://github.com/cal-itp/data-analyses/blob/dd3b5f963bfa480fb949c5949bea6485431361fe/gtfs_funnel/nacto_utils.py#L24-L58
		CASE
            WHEN route_type = "0" OR route_type = "1" OR route_type = "2" THEN "rail"
            WHEN route_type = "4" THEN "ferry"
            WHEN (
              CONTAINS_SUBSTR(route_name, "Express")
              OR CONTAINS_SUBSTR(route_name, "Limited")
            ) AND route_type = "3" THEN "express"
            WHEN CONTAINS_SUBSTR(route_name, "Rapid") AND route_type = "3" THEN "rapid"
            WHEN route_type = "3" THEN "bus"
            WHEN route_type = "5" THEN "cable_tram"
            WHEN route_type = "11" THEN "trolleybus"
            ELSE "unknown"
		END AS route_typology,
    FROM route_direction_aggregation
)

SELECT * FROM route_direction_aggregation_with_typology
