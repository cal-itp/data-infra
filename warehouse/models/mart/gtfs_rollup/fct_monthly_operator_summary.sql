{{ config(materialized='table') }}

WITH daily_summary AS (
    SELECT *
    FROM {{ ref('fct_daily_schedule_rt_operator_summary') }}
),

daily_summary2 AS (
    SELECT
        *,
        DATE_TRUNC(service_date, MONTH) AS month_first_day,
        {{ generate_day_type('service_date') }} AS day_type,
    FROM daily_summary
),

-- create pivot table that shows how many days in each gtfs_availability
day_counts_by_availability AS (
    SELECT
        *
    FROM (
        SELECT
            COALESCE(gtfs_dataset_name, schedule_name) AS schedule_name,
            schedule_base64_url,
            vp_base64_url,
            tu_base64_url,
            service_date,
            month_first_day,
            day_type,

            gtfs_availability,

        FROM daily_summary2
    )
    PIVOT(
        COUNT(DISTINCT service_date) AS n_days
        FOR gtfs_availability IN
        ("schedule_only", "schedule_and_rt", "schedule_and_tu_only", "schedule_and_vp_only")
    )
),

pivoted AS (
    SELECT
        schedule_name,
        schedule_base64_url,
        vp_base64_url,
        tu_base64_url,
        month_first_day,
        day_type,
        SUM(n_days_schedule_only) AS n_days_schedule_only,
        SUM(n_days_schedule_and_rt) AS n_days_schedule_and_rt,
        SUM(n_days_schedule_and_vp_only) AS n_days_schedule_and_vp_only,
        SUM(n_days_schedule_and_tu_only) AS n_days_schedule_and_tu_only,

    FROM day_counts_by_availability
    GROUP BY 1, 2, 3, 4, 5, 6
),

monthly_summary AS (
    SELECT

        EXTRACT(month FROM daily_summary2.month_first_day) AS month,
        EXTRACT(year FROM daily_summary2.month_first_day) AS year,
        daily_summary2.month_first_day,

        COALESCE(daily_summary2.gtfs_dataset_name, daily_summary2.schedule_name) AS schedule_name,
        daily_summary2.schedule_base64_url,
        vp_name,
        daily_summary2.vp_base64_url,
        tu_name,
        daily_summary2.tu_base64_url,

        daily_summary2.day_type,

        SUM(n_trips) AS n_trips,
        ROUND(SUM(n_trips) / COUNT(DISTINCT service_date), 1) AS daily_trips,
        ROUND(SUM(ttl_service_hours), 1) AS ttl_service_hours,
        ROUND(SUM(ttl_service_hours) / COUNT(DISTINCT service_date), 1) AS daily_service_hours,

        MAX(n_routes) AS n_routes,
        MAX(n_shapes) AS n_shapes,
        MAX(n_stops) AS n_stops,
        SUM(num_stop_times) AS num_stop_times,
        ROUND(SUM(num_stop_times) / COUNT(DISTINCT service_date), 1) AS daily_arrivals,

        COUNT(DISTINCT service_date) AS n_days,
        COUNT(DISTINCT feed_key) AS n_feeds,

        ROUND(AVG(vp_messages_per_minute), 1) AS vp_messages_per_minute,
        SUM(n_vp_trips) AS n_vp_trips,
        ROUND(SUM(n_vp_trips) / COUNT(DISTINCT service_date), 1) AS daily_vp_trips,
        ROUND(AVG(pct_vp_trips), 3) AS pct_vp_trips,
        MAX(pct_vp_routes) AS pct_vp_routes, -- should the max be used for coverage?
        SUM(vp_extract_duration_minutes) / COUNT(DISTINCT service_date) AS daily_vp_extract_duration_minutes,

        ROUND(AVG(tu_messages_per_minute), 1) AS tu_messages_per_minute,
        SUM(n_tu_trips) AS n_tu_trips,
        ROUND(SUM(n_tu_trips) / COUNT(DISTINCT service_date), 1) AS daily_tu_trips,
        ROUND(AVG(pct_tu_trips), 3) AS pct_tu_trips,
        MAX(pct_tu_routes) AS pct_tu_routes, -- should the max be used for coverage?
        SUM(tu_extract_duration_minutes) / COUNT(DISTINCT service_date) AS daily_tu_extract_duration_minutes,

        MAX(pivoted.n_days_schedule_only) AS n_days_schedule_only,
        MAX(pivoted.n_days_schedule_and_rt) AS n_days_schedule_and_rt,
        MAX(pivoted.n_days_schedule_and_vp_only) AS n_days_schedule_and_vp_only,
        MAX(pivoted.n_days_schedule_and_tu_only) AS n_days_schedule_and_tu_only,

    FROM daily_summary2
    LEFT JOIN pivoted
        ON daily_summary2.month_first_day = pivoted.month_first_day
        AND daily_summary2.schedule_name = pivoted.schedule_name
        AND daily_summary2.schedule_base64_url = pivoted.schedule_base64_url
        AND daily_summary2.vp_base64_url = pivoted.vp_base64_url
        AND daily_summary2.tu_base64_url = pivoted.tu_base64_url
        AND daily_summary2.day_type = pivoted.day_type
    GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10
)

SELECT * FROM monthly_summary
