{{
    config(
        materialized='view',
        partition_by={
            'field': 'service_date',
            'data_type': 'date',
            'granularity': 'day'
        },
        cluster_by=['tu_base64_url', 'tu_name', 'schedule_base64_url', 'schedule_name'],
    )
}}

WITH tu_trip_metrics AS (
    SELECT
        trip_summaries.service_date,
        trip_summaries.base64_url AS tu_base64_url,
        trip_summaries.schedule_base64_url,
        trip_summaries.trip_instance_key,

        trip_metrics.* EXCEPT(service_date, base64_url, trip_key),

    FROM {{ ref('fct_trip_updates_trip_metrics') }} AS trip_metrics
    INNER JOIN {{ ref('fct_trip_updates_trip_summaries') }} AS trip_summaries
        ON trip_summaries.service_date = trip_metrics.service_date
        AND trip_summaries.base64_url = trip_metrics.base64_url
        AND trip_summaries.key = trip_metrics.trip_key
        -- join tables with trip_key because it includes trip_id and trip_start_time
        -- this trip_key isn't carried into fct_observed_trips, because we use trip_instance_key downstream
),

-- we may not have a full month for these metrics to be calculated
-- however, we will want to average for the month for the n_days we do have
-- when we go from route_id->route_name, similar to how other monthly rollup tables are set up,
trip_join AS (
    SELECT
        tu_trip_metrics.service_date,
        schedule_rt_trips.tu_name,
        tu_trip_metrics.tu_base64_url,
        schedule_rt_trips.schedule_name,
        schedule_rt_trips.schedule_base64_url,
        schedule_rt_trips.route_name,
        COALESCE(schedule_rt_trips.direction_id, -1) AS direction_id, --get nulls switched for macro to work
        schedule_rt_trips.trip_instance_key,

        tu_trip_metrics.* EXCEPT(service_date, tu_base64_url, schedule_base64_url, trip_instance_key)

    FROM tu_trip_metrics
    INNER JOIN {{ ref('fct_daily_scheduled_rt_trips') }} AS schedule_rt_trips
        USING (service_date, schedule_base64_url, tu_base64_url, trip_instance_key)
    WHERE schedule_rt_trips.in_rt_only IS FALSE -- remove rows in full outer join that don't have schedule
),

tu_route_direction_aggregation AS (
    SELECT
        service_date,
        tu_name,
        tu_base64_url,
        schedule_name,
        schedule_base64_url,
        route_name,
        direction_id,

        ROUND(AVG(avg_prediction_error_sec), 2) AS avg_prediction_error_sec,

        ROUND(SUM(n_tu_accurate_minutes) / SUM(n_tu_minutes_available), 3) AS pct_tu_accurate_minutes,
        ROUND(SUM(n_tu_complete_minutes) / SUM(n_tu_minutes_available), 3) AS pct_tu_complete_minutes,

        SUM(n_tu_minutes_available) AS n_tu_minutes_available,

        ROUND(AVG(avg_prediction_spread_minutes), 2) AS avg_prediction_spread_minutes,
        SUM(n_predictions) AS n_predictions,
        ROUND(SUM(n_predictions_early) / SUM(n_predictions), 2) AS pct_predictions_early,
        ROUND(SUM(n_predictions_ontime) / SUM(n_predictions), 2) AS pct_predictions_ontime,
        ROUND(SUM(n_predictions_late) / SUM(n_predictions), 2) AS pct_predictions_late,

        ARRAY_CONCAT_AGG(prediction_error_by_minute_array) AS prediction_error_by_minute_array,
        ARRAY_CONCAT_AGG(scaled_prediction_error_by_minute_array) AS scaled_prediction_error_by_minute_array,

        COUNT(DISTINCT trip_instance_key) AS n_tu_trips,
        SUM(n_tu_stops) AS n_tu_stops,

    FROM trip_join
    GROUP BY service_date, tu_name, tu_base64_url, schedule_name, schedule_base64_url, route_name, direction_id
),

prediction_array_results AS (
    {{ unscaled_and_scaled_prediction_error_percentiles_by_group(
        'trip_join',
        ('service_date', 'tu_base64_url', 'schedule_base64_url',
        'route_name', 'direction_id')
    )
    }}
),

-- join all calculated trip update metrics
tu_route_dir_metrics AS (
    SELECT
        tu_route_direction_aggregation.service_date,
        tu_route_direction_aggregation.tu_name,
        tu_route_direction_aggregation.tu_base64_url,
        tu_route_direction_aggregation.schedule_name,
        tu_route_direction_aggregation.schedule_base64_url,
        tu_route_direction_aggregation.route_name,
        CASE
            WHEN tu_route_direction_aggregation.direction_id = -1 THEN NULL
            ELSE tu_route_direction_aggregation.direction_id
        END AS direction_id, -- change the -1 direction_id values back to nulls

        tu_route_direction_aggregation.* EXCEPT(service_date, tu_name, tu_base64_url, schedule_name, schedule_base64_url, route_name, direction_id),

        prediction_array_results.* EXCEPT(service_date, tu_base64_url, schedule_base64_url, route_name, direction_id)

    FROM tu_route_direction_aggregation
    LEFT JOIN prediction_array_results
        USING (service_date, tu_base64_url, schedule_base64_url, route_name, direction_id)
)

SELECT * FROM tu_route_dir_metrics
