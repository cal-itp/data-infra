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

WITH fct_stop_time_metrics AS (
    SELECT *
    FROM `cal-itp-data-infra-staging.tiffany_mart_gtfs.fct_stop_time_metrics`--{{ ref('fct_stop_time_metrics') }}

),

trip_metrics AS (
    SELECT
        base64_url,
        service_date,
        trip_key, -- use this to join with fct_trip_updates_trip_summaries.key

        AVG(avg_prediction_error_sec) AS avg_prediction_error_sec,

        SUM(n_tu_accurate_minutes) AS n_tu_accurate_minutes,
        SUM(n_tu_complete_minutes) AS n_tu_complete_minutes,

        SUM(n_tu_minutes_available) AS n_tu_minutes_available,
        ROUND(
            SAFE_DIVIDE(
                SUM(sum_prediction_spread_seconds),
                SUM(max_minutes_until_arrival)
        ) / 60, 2) AS avg_prediction_spread_minutes,
        SUM(n_predictions) AS n_predictions,

        SUM(n_predictions_early) AS n_predictions_early,
        SUM(n_predictions_ontime) AS n_predictions_ontime,
        SUM(n_predictions_late) AS n_predictions_late,

        COUNT(DISTINCT key) AS n_tu_stops,

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
    GROUP BY 1, 2, 3
    -- aggregate to service_date-trip grain (lose stop_id and stop_sequence)
)

SELECT * FROM trip_metrics
