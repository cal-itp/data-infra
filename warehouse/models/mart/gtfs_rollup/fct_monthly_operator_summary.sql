{{ config(materialized='table') }}

WITH daily_summary AS (
    SELECT
        *,
        DATE_TRUNC(service_date, MONTH) AS month_first_day,
        {{ generate_day_type('service_date') }} AS day_type,
    FROM {{ ref('fct_daily_schedule_rt_operator_summary') }}
),

tu_stop_metrics AS ( -- noqa: L045
    SELECT
        service_date,
        DATE_TRUNC(service_date, MONTH) AS month_first_day,
        {{ generate_day_type('service_date') }} AS day_type,
        base64_url,
        schedule_base64_url,
        prediction_error_by_minute_array,
        scaled_prediction_error_by_minute_array,
    FROM `cal-itp-data-infra.mart_gtfs.fct_trip_updates_stop_metrics`--{{ ref('fct_trip_updates_stop_metrics') }}
    WHERE service_date >= "2026-10-01"
),

prediction_array_results AS (
    {{ unscaled_and_scaled_prediction_error_percentiles_by_group(
        'tu_stop_metrics',
        ('month_first_day', 'day_type', 'base64_url', 'schedule_base64_url')
    )
    }}
),

-- create pivot table that shows how many days in each gtfs_availability
day_counts_by_availability AS (
    SELECT
        *
    FROM (
        SELECT
            schedule_name,
            schedule_base64_url,
            vp_base64_url,
            tu_base64_url,
            service_date,
            month_first_day,
            day_type,

            gtfs_availability,

        FROM daily_summary
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

        EXTRACT(month FROM daily_summary.month_first_day) AS month,
        EXTRACT(year FROM daily_summary.month_first_day) AS year,
        daily_summary.month_first_day,

        daily_summary.schedule_name,
        daily_summary.schedule_base64_url,
        vp_name,
        daily_summary.vp_base64_url,
        tu_name,
        daily_summary.tu_base64_url,

        daily_summary.day_type,

        -- schedule
        SUM(n_trips) AS n_trips,
        SUM(n_trip_instances) AS n_trip_instances,
        ROUND(SUM(n_trips) / COUNT(DISTINCT service_date), 1) AS daily_trips,
        ROUND(SUM(n_trip_instances) / COUNT(DISTINCT service_date), 1) AS daily_trip_instances,
        ROUND(SUM(ttl_service_hours), 1) AS ttl_service_hours,
        ROUND(SUM(ttl_service_hours) / COUNT(DISTINCT service_date), 1) AS daily_service_hours,
        MAX(n_routes) AS n_routes,
        MAX(n_shapes) AS n_shapes,
        MAX(n_stops) AS n_stops,
        SUM(num_stop_times) AS ttl_arrivals,
        ROUND(SUM(num_stop_times) / COUNT(DISTINCT service_date), 1) AS daily_arrivals,

        -- flex and demand response
        SUM(n_flex_trips) AS n_flex_trips,
        ROUND(SUM(n_flex_trips) / COUNT(DISTINCT service_date), 1) AS daily_flex_trips,
        ROUND(SUM(ttl_flex_service_hours), 1) AS ttl_flex_service_hours,
        ROUND(SUM(ttl_flex_service_hours) / COUNT(DISTINCT service_date), 1) AS daily_flex_service_hours,
        SUM(num_gtfs_flex_stop_times) AS ttl_flex_arrivals,
        ROUND(SUM(num_gtfs_flex_stop_times) / COUNT(DISTINCT service_date), 1) AS daily_flex_arrivals,
        SUM(n_demand_response_trips) AS n_demand_response_trips,
        ROUND(SUM(n_demand_response_trips) / COUNT(DISTINCT service_date), 1) AS daily_demand_response_trips,

        -- vehicle positions
        ROUND(AVG(vp_messages_per_minute), 1) AS vp_messages_per_minute,
        SUM(n_vp_trips) AS n_vp_trips,
        ROUND(SUM(n_vp_trips) / COUNT(DISTINCT service_date), 1) AS daily_vp_trips,
        ROUND(AVG(pct_vp_trips), 3) AS pct_vp_trips,
        MAX(pct_vp_routes) AS pct_vp_routes, -- should the max be used for coverage?
        ROUND(SUM(vp_extract_duration_minutes) / COUNT(DISTINCT service_date), 2) AS daily_vp_extract_duration_minutes,

        -- trip update
        ROUND(AVG(tu_messages_per_minute), 1) AS tu_messages_per_minute,
        SUM(n_tu_trips) AS n_tu_trips,
        ROUND(SUM(n_tu_trips) / COUNT(DISTINCT service_date), 1) AS daily_tu_trips,
        ROUND(AVG(pct_tu_trips), 3) AS pct_tu_trips,
        MAX(pct_tu_routes) AS pct_tu_routes, -- should the max be used for coverage?
        ROUND(SUM(tu_extract_duration_minutes) / COUNT(DISTINCT service_date), 2) AS daily_tu_extract_duration_minutes,

        ROUND(AVG(pct_tu_complete_minutes), 3) AS pct_tu_complete_minutes,
        ROUND(AVG(pct_tu_accurate_minutes), 3) AS pct_tu_accurate_minutes,
        ROUND(AVG(avg_prediction_spread_minutes), 1) AS avg_prediction_spread_minutes,
        SUM(n_predictions) AS n_predictions,
        ROUND(AVG(pct_predictions_early), 3) AS pct_predictions_early,
        ROUND(AVG(pct_predictions_ontime), 3) AS pct_predictions_ontime,
        ROUND(AVG(pct_predictions_late), 3) AS pct_predictions_late,

        -- feed aggregation
        COUNT(DISTINCT service_date) AS n_days,
        COUNT(DISTINCT feed_key) AS n_feeds,
        MAX(pivoted.n_days_schedule_only) AS n_days_schedule_only,
        MAX(pivoted.n_days_schedule_and_rt) AS n_days_schedule_and_rt,
        MAX(pivoted.n_days_schedule_and_vp_only) AS n_days_schedule_and_vp_only,
        MAX(pivoted.n_days_schedule_and_tu_only) AS n_days_schedule_and_tu_only,

    FROM daily_summary
    LEFT JOIN pivoted
        ON daily_summary.month_first_day = pivoted.month_first_day
        AND daily_summary.schedule_name = pivoted.schedule_name
        AND daily_summary.schedule_base64_url = pivoted.schedule_base64_url
        AND daily_summary.vp_base64_url = pivoted.vp_base64_url
        AND daily_summary.tu_base64_url = pivoted.tu_base64_url
        AND daily_summary.day_type = pivoted.day_type
    GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10
),

monthly_summary2 AS (
    SELECT
        monthly_summary.*,
        prediction_array_results.* EXCEPT(month_first_day, day_type, base64_url, schedule_base64_url)
    FROM monthly_summary
    LEFT JOIN prediction_array_results
        ON monthly_summary.month_first_day = prediction_array_results.month_first_day
        AND monthly_summary.day_type = prediction_array_results.day_type
        AND monthly_summary.tu_base64_url = prediction_array_results.base64_url
        AND monthly_summary.schedule_base64_url = prediction_array_results.schedule_base64_url
)

SELECT * FROM monthly_summary2
