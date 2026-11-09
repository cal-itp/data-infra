{{
    config(
        materialized='view',
        partition_by={
            'field': 'month_first_day',
            'data_type': 'date',
            'granularity': 'month'
        },
        cluster_by=['month_first_day', 'tu_base64_url', 'tu_name'],
    )
}}

WITH daily_tu_metrics AS (
    SELECT
        * EXCEPT(direction_id),
        COALESCE(direction_id, -1) AS direction_id, -- fill nulls for macro to work

        DATE_TRUNC(service_date, MONTH) AS month_first_day,
        {{ generate_day_type('service_date') }} AS day_type,
    FROM {{ ref('fct_daily_trip_updates_route_direction_metrics') }}
),

prediction_array_results AS (
    {{ unscaled_and_scaled_prediction_error_percentiles_by_group(
        'daily_tu_metrics',
        ('month_first_day', 'day_type', 'tu_base64_url', 'schedule_base64_url', 'route_name', 'direction_id')
    )
    }}
),

tu_route_direction_aggregation AS (
    SELECT
        month_first_day,
        day_type,
        tu_name,
        tu_base64_url,
        schedule_name,
        schedule_base64_url,
        route_name,
        direction_id,

        ROUND(AVG(avg_prediction_error_sec), 2) AS avg_prediction_error_sec,

        ROUND(AVG(pct_tu_accurate_minutes), 3) AS pct_tu_accurate_minutes,
        ROUND(AVG(pct_tu_complete_minutes), 3) AS pct_tu_complete_minutes,

        ROUND(AVG(avg_prediction_spread_minutes), 1) AS avg_prediction_spread_minutes,
        SUM(n_predictions) AS n_predictions,

        ROUND(AVG(pct_predictions_early), 3) AS pct_predictions_early,
        ROUND(AVG(pct_predictions_ontime), 3) AS pct_predictions_ontime,
        ROUND(AVG(pct_predictions_late), 3) AS pct_predictions_late,

        SUM(n_tu_trips) AS n_tu_trips,
        SUM(n_tu_stops) AS n_tu_stops,

    FROM daily_tu_metrics
    GROUP BY 1, 2, 3, 4, 5, 6, 7, 8
),

-- join all calculated trip update metrics
tu_route_dir_metrics AS (
    SELECT
        tu_route_direction_aggregation.month_first_day,
        tu_route_direction_aggregation.day_type,
        tu_route_direction_aggregation.tu_name,
        tu_route_direction_aggregation.tu_base64_url,
        tu_route_direction_aggregation.schedule_name,
        tu_route_direction_aggregation.schedule_base64_url,
        tu_route_direction_aggregation.route_name,
        CASE
            WHEN tu_route_direction_aggregation.direction_id = -1 THEN NULL
            ELSE tu_route_direction_aggregation.direction_id
        END AS direction_id, -- change the -1 direction_id values back to nulls

        tu_route_direction_aggregation.* EXCEPT(month_first_day, day_type, tu_name, tu_base64_url, schedule_name, schedule_base64_url, route_name, direction_id),

        prediction_array_results.* EXCEPT(month_first_day, day_type, tu_base64_url, schedule_base64_url, route_name, direction_id)

    FROM tu_route_direction_aggregation
    LEFT JOIN prediction_array_results
        USING (month_first_day, day_type, tu_base64_url, schedule_base64_url, route_name, direction_id)
)

SELECT * FROM tu_route_dir_metrics
