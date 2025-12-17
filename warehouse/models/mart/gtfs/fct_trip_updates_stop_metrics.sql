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
    WHERE {{ incremental_where(
        default_start_var='PROD_GTFS_RT_START',
        this_dt_column='service_date',
        filter_dt_column='service_date',
        dev_lookback_days = 250)
    }} AND service_date >= '2025-06-01' AND service_date <= '2025-06-15'
),

rt_feeds AS (
    SELECT DISTINCT
        base64_url,
        schedule_feed_key
    FROM `cal-itp-data-infra.mart_gtfs.fct_daily_rt_feed_files` --{{ ref('fct_daily_rt_feed_files') }}
),

daily_scheduled_stops AS (
    SELECT
        key,
        feed_key,
        service_date,
        stop_id,
        stop_key
    FROM `cal-itp-data-infra.mart_gtfs.fct_daily_scheduled_stops` AS stops--{{ ref('fct_daily_scheduled_stops') }} AS stops
    INNER JOIN rt_feeds
        ON rt_feeds.schedule_feed_key = stops.feed_key
    WHERE service_date >= '2025-06-01' AND service_date <= '2025-06-15'
),

stop_metrics AS (
    SELECT
        -- this key is service_date and stop_key
        daily_scheduled_stops.key,
        -- this key is dim_stops, which is feed_key/line_number,
        -- we need this to get stop pt_geom, etc
        daily_scheduled_stops.stop_key,

        fct_stop_time_metrics.base64_url,
        fct_stop_time_metrics.service_date,
        fct_stop_time_metrics.stop_id,
        rt_feeds.schedule_feed_key,

        AVG(fct_stop_time_metrics.avg_prediction_error_sec) AS avg_prediction_error_sec,

        SUM(fct_stop_time_metrics.n_tu_accurate_minutes) AS n_tu_accurate_minutes,
        SUM(fct_stop_time_metrics.n_tu_complete_minutes) AS n_tu_complete_minutes,
        SUM(fct_stop_time_metrics.n_tu_minutes_available) AS n_tu_minutes_available,

        -- safe_divide because there are some rows where denominator is 0
        SAFE_DIVIDE(SUM(fct_stop_time_metrics.sum_prediction_spread_minutes),  SUM(fct_stop_time_metrics.max_minutes_until_arrival)) AS avg_prediction_spread_minutes,

        SUM(fct_stop_time_metrics.n_predictions) AS n_predictions,
        SUM(fct_stop_time_metrics.n_predictions_early) AS n_predictions_early,
        SUM(fct_stop_time_metrics.n_predictions_ontime) AS n_predictions_ontime,
        SUM(fct_stop_time_metrics.n_predictions_late) AS n_predictions_late,

        -- this key comes from intermediate and approximates trip_instance_key,
        -- which is available in fct_trip_updates_trip_summaries
        COUNT(DISTINCT fct_stop_time_metrics.trip_key) AS n_tu_trips,

        -- check how combining these arrays (stop_time to stop grain) works for error percentiles
        ARRAY_CONCAT_AGG(fct_stop_time_metrics.prediction_error_by_minute_array) AS prediction_error_by_minute_array,
        ARRAY_CONCAT_AGG(fct_stop_time_metrics.scaled_prediction_error_by_minute_array) AS scaled_prediction_error_by_minute_array,
        ARRAY_CONCAT_AGG(fct_stop_time_metrics.minutes_until_arrival_array) AS minutes_until_arrival_array,

    FROM fct_stop_time_metrics
    INNER JOIN rt_feeds
        ON fct_stop_time_metrics.base64_url = rt_feeds.base64_url
    INNER JOIN daily_scheduled_stops
        ON fct_stop_time_metrics.service_date = daily_scheduled_stops.service_date
        AND rt_feeds.schedule_feed_key = daily_scheduled_stops.feed_key
        AND fct_stop_time_metrics.stop_id = daily_scheduled_stops.stop_id
    GROUP BY 1, 2, 3, 4, 5, 6
    -- aggregate to service_date-stop grain (lose trip_id/tu_trip_key and stop_sequence)
)

SELECT * FROM stop_metrics
