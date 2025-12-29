{{
    config(
        materialized='incremental',
        incremental_strategy = 'insert_overwrite',
        partition_by={
            'field': 'service_date',
            'data_type': 'date',
            'granularity': 'day'
        }, cluster_by=['service_date', 'base64_url']
    )
}}

-- this goes into fct_observed_stops
WITH fct_stop_time_metrics AS (
    SELECT *
    FROM {{ ref('fct_stop_time_metrics') }}
    WHERE {{ incremental_where(
        default_start_var='PROD_GTFS_RT_START',
        this_dt_column='service_date',
        filter_dt_column='service_date',
    )
    }}
),

stop_metrics AS (
    SELECT
        base64_url,
        schedule_base64_url,
        service_date,
        stop_id,

        AVG(avg_prediction_error_sec) AS avg_prediction_error_sec,

        SUM(n_tu_accurate_minutes) AS n_tu_accurate_minutes,
        SUM(n_tu_complete_minutes) AS n_tu_complete_minutes,
        SUM(n_tu_minutes_available) AS n_tu_minutes_available,

        -- safe_divide because there are some rows where denominator is 0
        ROUND(SAFE_DIVIDE(
            SUM(sum_prediction_spread_seconds),
            SUM(max_minutes_until_arrival)
        ) / 60, 2) AS avg_prediction_spread_minutes,

        SUM(n_predictions) AS n_predictions,
        SUM(n_predictions_early) AS n_predictions_early,
        SUM(n_predictions_ontime) AS n_predictions_ontime,
        SUM(n_predictions_late) AS n_predictions_late,

        -- this key comes from intermediate and approximates trip_instance_key,
        -- which is available in fct_trip_updates_trip_summaries
        COUNT(DISTINCT trip_key) AS n_tu_trips,

        -- check how combining these arrays (stop_time to stop grain) works for error percentiles
        -- order by stop_time_key each time so arrays don't lose order when we combine
        ARRAY_CONCAT_AGG(
            prediction_error_by_minute_array
            ORDER BY key
        ) AS prediction_error_by_minute_array,
        ARRAY_CONCAT_AGG(
            scaled_prediction_error_by_minute_array
            ORDER BY key
        ) AS scaled_prediction_error_by_minute_array,
        ARRAY_CONCAT_AGG(
            minutes_until_arrival_array
            ORDER BY key
        ) AS minutes_until_arrival_array,

    FROM fct_stop_time_metrics
    GROUP BY 1, 2, 3, 4
    -- aggregate to service_date-stop grain (lose trip_id/tu_trip_key and stop_sequence)
)

SELECT * FROM stop_metrics
