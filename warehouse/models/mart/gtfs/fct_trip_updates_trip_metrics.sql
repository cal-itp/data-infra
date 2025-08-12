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
    FROM {{ ref('fct_stop_time_metrics') }}
),

trip_metrics AS (
    SELECT
        base64_url,
        service_date,
        trip_key, -- use this to join with fct_trip_updates_trip_summaries.key

        AVG(fct_stop_time_metrics.avg_prediction_error_sec) AS avg_prediction_error_sec,

        SUM(fct_stop_time_metrics.n_tu_accurate_minutes) AS n_tu_accurate_minutes,
        SUM(fct_stop_time_metrics.n_tu_complete_minutes) AS n_tu_complete_minutes,

        SUM(fct_stop_time_metrics.n_tu_minutes_available) AS n_tu_minutes_available,
        AVG(fct_stop_time_metrics.avg_prediction_spread_minutes) AS avg_prediction_spread_minutes,
        SUM(fct_stop_time_metrics.n_predictions) AS n_predictions,

        COUNT(DISTINCT fct_stop_time_metrics.key) AS n_stops,

    FROM fct_stop_time_metrics
    GROUP BY 1, 2, 3
    -- aggregate to service_date-trip grain (lose stop_id and stop_sequence)
)

SELECT * FROM trip_metrics
