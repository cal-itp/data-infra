{{
    config(
        materialized='table',
        cluster_by=['month_first_day', 'schedule_name']
    )
}}

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
            schedule_name,
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
        month_first_day,
        day_type,
        SUM(n_days_schedule_only) AS n_days_schedule_only,
        SUM(n_days_schedule_and_rt) AS n_days_schedule_and_rt,
        SUM(n_days_schedule_and_vp_only) AS n_days_schedule_and_vp_only,
        SUM(n_days_schedule_and_tu_only) AS n_days_schedule_and_tu_only,

    FROM day_counts_by_availability
    GROUP BY 1, 2, 3
),


monthly_summary AS (
    SELECT

        EXTRACT(month FROM daily_summary2.month_first_day) AS month,
        EXTRACT(year FROM daily_summary2.month_first_day) AS year,
        daily_summary2.month_first_day,
        daily_summary2.schedule_name,
        schedule_base64_url,
        vp_name,
        vp_base64_url,
        tu_name,
        tu_base64_url,

        daily_summary2.day_type,
        -- hopefully if there are nulls on specific days, we can capture it still
        MAX(analysis_name) AS analysis_name,

        SUM(n_trips) AS n_trips,
        ROUND(SUM(n_trips) / COUNT(DISTINCT service_date), 1) AS daily_trips,
        ROUND(SUM(ttl_service_hours), 1) AS ttl_service_hours,
        AVG(n_routes) AS n_routes,
        COUNT(DISTINCT service_date) AS n_days,

        ROUND(AVG(vp_messages_per_minute), 1) AS vp_messages_per_minute,
        SUM(n_vp_trips) AS n_vp_trips,
        ROUND(SUM(n_vp_trips) / COUNT(DISTINCT service_date), 1) AS daily_vp_trips,
        ROUND(AVG(pct_vp_trips), 3) AS pct_vp_trips,
        ROUND(AVG(n_vp_routes), 1) AS n_vp_routes,
        ROUND(AVG(pct_vp_service_hours), 3) AS pct_vp_service_hours,

        ROUND(AVG(tu_messages_per_minute), 1) AS tu_messages_per_minute,
        SUM(n_tu_trips) AS n_tu_trips,
        ROUND(SUM(n_tu_trips) / COUNT(DISTINCT service_date), 1) AS daily_tu_trips,
        ROUND(AVG(pct_tu_trips), 3) AS pct_tu_trips,
        ROUND(AVG(n_tu_routes), 1) AS n_tu_routes,
        ROUND(AVG(pct_tu_service_hours), 3) AS pct_tu_service_hours,

    FROM daily_summary2
    INNER JOIN pivoted
        ON daily_summary2.month_first_day = pivoted.month_first_day
        AND daily_summary2.schedule_name = pivoted.schedule_name
        AND daily_summary2.day_type = pivoted.day_type
    GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10
)

SELECT * FROM monthly_summary
