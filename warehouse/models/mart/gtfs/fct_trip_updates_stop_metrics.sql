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
    WHERE service_date = "2025-06-24"
),

daily_scheduled_stops AS (
    SELECT
        key,
        feed_key,
        service_date,
        stop_id,
        stop_key
    FROM `cal-itp-data-infra.mart_gtfs.fct_daily_scheduled_stops`
    --FROM {{ ref('fct_daily_scheduled_stops') }}
    WHERE service_date = "2025-06-24"
),

rt_feeds AS (
    SELECT DISTINCT
        base64_url,
        schedule_feed_key
    FROM `cal-itp-data-infra.mart_gtfs.fct_daily_rt_feed_files`--{{ ref('fct_daily_rt_feed_files') }}
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
        AVG(fct_stop_time_metrics.avg_prediction_spread_minutes) AS avg_prediction_spread_minutes,
        SUM(fct_stop_time_metrics.n_predictions) AS n_predictions,

        -- this key comes from intermediate and approximates trip_instance_key,
        -- which is available in fct_trip_updates_trip_summaries
        COUNT(DISTINCT fct_stop_time_metrics.trip_key) AS n_trips,

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
