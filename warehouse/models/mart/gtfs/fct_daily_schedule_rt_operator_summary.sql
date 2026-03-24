{{
    config(
        materialized='table',
        cluster_by=['service_date']
    )
}}

WITH daily_schedule AS (
    SELECT *
    FROM {{ ref('fct_daily_feed_scheduled_service_summary') }}
),

daily_rt AS (
    SELECT *
    FROM {{ ref('fct_daily_rt_service_summary') }}
),

-- these will not be present for each date,
-- so use left join when bringing it in with daily schedule / daily RT
daily_tu_stop_metrics AS (
    SELECT *
    FROM {{ ref('fct_trip_updates_stop_metrics') }}
),

tu_operator_aggregation AS (
    SELECT
        service_date,
        base64_url,
        schedule_base64_url,

        ROUND(SUM(n_tu_complete_minutes) / SUM(n_tu_minutes_available), 3) AS pct_tu_complete_minutes,
        ROUND(SUM(n_tu_accurate_minutes) / SUM(n_tu_minutes_available), 3) AS pct_tu_accurate_minutes,
        ROUND(AVG(avg_prediction_spread_minutes), 2) AS avg_prediction_spread_minutes,
        SUM(n_predictions) AS n_predictions,
        ROUND(SUM(n_predictions_early) / SUM(n_predictions), 2) AS pct_predictions_early,
        ROUND(SUM(n_predictions_ontime) / SUM(n_predictions), 2) AS pct_predictions_ontime,
        ROUND(SUM(n_predictions_late) / SUM(n_predictions), 2) AS pct_predictions_late,

    FROM daily_tu_stop_metrics
    GROUP BY service_date, base64_url, schedule_base64_url
),

prediction_error_by_operator AS (
    {{ get_percentiles_by_group(
        'daily_tu_stop_metrics',
        ('service_date', 'base64_url', 'schedule_base64_url'),
        array_col='prediction_error_by_minute_array',
        decimals=1)
    }}
),

scaled_prediction_error_by_operator AS (
    {{ get_percentiles_by_group(
        'daily_tu_stop_metrics',
        ('service_date', 'base64_url', 'schedule_base64_url'),
        array_col='scaled_prediction_error_by_minute_array',
        decimals=3)
    }}
),

-- join all calculated trip update metrics
tu_operator_metrics AS (
    SELECT
        tu_operator_aggregation.*,

        pe.value_array AS prediction_error_sec_array,
        pe.value_percentile_array AS prediction_error_sec_percentile_array,

        spe.value_array AS scaled_prediction_error_sec_array,
        spe.value_percentile_array AS scaled_prediction_error_sec_percentile_array,

    FROM tu_operator_aggregation
    INNER JOIN prediction_error_by_operator AS pe
        USING (service_date, base64_url, schedule_base64_url)
    INNER JOIN scaled_prediction_error_by_operator AS spe
        USING (service_date, base64_url, schedule_base64_url)
),

daily_summary AS (
    SELECT
        COALESCE(daily_schedule.service_date, daily_rt.service_date) AS service_date,
        daily_schedule.feed_key,
        daily_schedule.gtfs_dataset_key, -- should get rid of a set of these so schedule keys aren't doubled up...once we figure out how to tag cases
        daily_schedule.gtfs_dataset_name,
        daily_schedule.ttl_service_hours,
        COALESCE(daily_schedule.n_trips, 0) AS n_trips,
        daily_schedule.first_departure_sec,
        daily_schedule.last_arrival_sec,
        daily_schedule.num_stop_times,
        daily_schedule.n_routes,
        daily_schedule.n_shapes,
        daily_schedule.n_stops,
        daily_schedule.contains_warning_duplicate_stop_times_primary_key,
        daily_schedule.contains_warning_duplicate_trip_primary_key,
        daily_schedule.contains_warning_missing_foreign_key_stop_id,

        daily_rt.schedule_base64_url,
        daily_rt.schedule_gtfs_dataset_key,
        daily_rt.schedule_name,
        daily_rt.vp_gtfs_dataset_key,
        daily_rt.vp_name,
        daily_rt.vp_base64_url,
        daily_rt.tu_gtfs_dataset_key,
        daily_rt.tu_name,
        daily_rt.tu_base64_url,

        -- trip updates
        COALESCE(daily_rt.n_tu_trips, 0) AS n_tu_trips,
        ROUND(SAFE_DIVIDE(daily_rt.n_vp_trips, daily_schedule.n_trips), 3) AS pct_tu_trips,
        daily_rt.n_tu_routes,
        ROUND(SAFE_DIVIDE(daily_rt.n_tu_routes, daily_schedule.n_routes), 3) AS pct_tu_routes,
        daily_rt.tu_extract_duration_minutes,
        daily_rt.tu_messages_per_minute,

        tu_operator_metrics.pct_tu_complete_minutes,
        tu_operator_metrics.pct_tu_accurate_minutes,
        tu_operator_metrics.avg_prediction_spread_minutes,
        tu_operator_metrics.n_predictions,
        tu_operator_metrics.pct_predictions_early,
        tu_operator_metrics.pct_predictions_ontime,
        tu_operator_metrics.pct_predictions_late,
        tu_operator_metrics.prediction_error_sec_array,
        tu_operator_metrics.prediction_error_sec_percentile_array,
        tu_operator_metrics.scaled_prediction_error_sec_array,
        tu_operator_metrics.scaled_prediction_error_sec_percentile_array,

        -- vehicle positions
        daily_rt.vp_num_distinct_updates,
        COALESCE(daily_rt.n_vp_trips, 0) AS n_vp_trips,
        ROUND(SAFE_DIVIDE(daily_rt.n_vp_trips, daily_schedule.n_trips), 3) AS pct_vp_trips,
        daily_rt.n_vp_routes,
        ROUND(SAFE_DIVIDE(daily_rt.n_vp_routes, daily_schedule.n_routes), 3) AS pct_vp_routes,
        daily_rt.vp_extract_duration_minutes,
        daily_rt.vp_messages_per_minute,

        -- figure out which ones are missing
        IF(gtfs_dataset_name IS NULL AND daily_schedule.feed_key IS NULL AND schedule_name IS NOT NULL, 1, 0) AS in_obs_only,

    FROM daily_schedule
    FULL OUTER JOIN daily_rt -- full outer join to see which ones don't match up
        ON daily_schedule.service_date = daily_rt.service_date
        AND daily_schedule.gtfs_dataset_name = daily_rt.schedule_name
        AND daily_schedule.gtfs_dataset_key = daily_rt.schedule_gtfs_dataset_key
    LEFT JOIN tu_operator_metrics
        ON daily_rt.service_date = tu_operator_metrics.service_date
        AND daily_rt.tu_base64_url = tu_operator_metrics.base64_url
        AND daily_rt.schedule_base64_url = tu_operator_metrics.schedule_base64_url
),

daily_summary2 AS (
    SELECT
        *,

        -- saw that some operators had only vp but not tu, so let's differentiate
        CASE
            WHEN n_trips > 0 AND n_tu_trips = 0 AND n_vp_trips = 0 THEN "schedule_only"
            WHEN n_trips > 0 AND n_tu_trips > 0 AND n_vp_trips > 0 THEN "schedule_and_rt"
            WHEN n_trips > 0 AND n_tu_trips > 0 AND n_vp_trips = 0 THEN "schedule_and_tu_only"
            WHEN n_trips > 0 AND n_tu_trips = 0 AND n_vp_trips > 0 THEN "schedule_and_vp_only"
            WHEN n_trips = 0 THEN "no_active_service"
            -- there are rows with active service but quartet hasn't been implemented yet, these cover 2022-10-01 values and before
            WHEN gtfs_dataset_name IS NULL AND feed_key IS NOT NULL THEN "v1_warehouse"
            ELSE "unknown"
        END AS gtfs_availability,
    FROM daily_summary
)

SELECT * FROM daily_summary2
