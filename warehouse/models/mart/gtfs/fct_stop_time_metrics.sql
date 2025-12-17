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

WITH int_tu_trip_stop AS (
    SELECT *
    FROM {{ ref('test_int_gtfs_rt__trip_updates_trip_stop_day_map_grouping') }}
    WHERE dt >= "2025-06-02" AND dt <= "2025-06-03"
),

tu_trip_keys AS (
    SELECT
        key AS trip_key,
        dt,
        service_date,
        base64_url,
        schedule_base64_url,
        trip_id,
        trip_start_time

    --FROM {{ ref('int_gtfs_rt__trip_updates_trip_day_map_grouping') }}
    FROM `cal-itp-data-infra.staging.int_gtfs_rt__trip_updates_trip_day_map_grouping`
    WHERE dt >= "2025-06-01" AND dt <= "2025-06-03"
),

unnested AS (
    SELECT

      * EXCEPT(_extract_ts_array, arrival_time_array, departure_time_array, offset0, offset1, offset2),
      EXTRACT(HOUR FROM _extract_ts) AS extract_hour,
      EXTRACT(MINUTE FROM _extract_ts) AS extract_minute,

    FROM int_tu_trip_stop
    LEFT JOIN UNNEST(_extract_ts_array) AS _extract_ts WITH OFFSET AS offset0
    LEFT JOIN UNNEST(arrival_time_array) AS arrival_time WITH OFFSET AS offset1
    LEFT JOIN UNNEST(departure_time_array) AS departure_time WITH OFFSET AS offset2
    WHERE offset0 = offset1 AND offset1 = offset2
),

prediction_difference AS (
    SELECT
        dt,
        service_date,
        base64_url,
        schedule_base64_url,
        trip_id,
        trip_start_time,
        stop_id,
        stop_sequence,
        key,
        extract_hour,
        extract_minute,

        arrival_time,
        actual_arrival,
        actual_departure,

        DATETIME_DIFF(actual_arrival, arrival_time, SECOND) AS prediction_seconds_difference_from_arrival,
        DATETIME_DIFF(actual_departure, arrival_time, SECOND) AS predictions_seconds_difference_from_departure,
        DATETIME_DIFF(actual_arrival, _extract_ts, MINUTE) as minutes_until_arrival,

     -- categorize whether prediction was early/on-time/late
        CASE
            WHEN (DATETIME_DIFF(actual_arrival, arrival_time, SECOND) > 0 AND DATETIME_DIFF(actual_departure, arrival_time, SECOND) > 0) THEN "is_early"
            WHEN (DATETIME_DIFF(actual_arrival, arrival_time, SECOND) < 0 AND DATETIME_DIFF(actual_departure, arrival_time, SECOND) < 0) THEN "is_late"
            WHEN (DATETIME_DIFF(actual_arrival, arrival_time, SECOND) = 0 OR DATETIME_DIFF(actual_departure, arrival_time, SECOND) = 0) THEN "is_ontime"
            ELSE "uncategorized"
        END AS prediction_category

    FROM unnested
),

predictions_categorized AS (
    SELECT
        *,
        -- Newmark overwrites some of these as 0 if is_ontime is True and the prediction is compared to actual arrival for early; actual departure for late
        CASE
            WHEN prediction_category = "is_ontime" THEN 0
            WHEN prediction_category = "is_early" THEN prediction_seconds_difference_from_arrival
            WHEN prediction_category = "is_late" THEN predictions_seconds_difference_from_departure
        END AS prediction_seconds_difference,
        -- save out boolean dummy variables
        COALESCE(prediction_category="is_ontime", True) AS is_ontime,
        COALESCE(prediction_category="is_early", True) AS is_early,
        COALESCE(prediction_category="is_late", True) AS is_late,
    FROM prediction_difference
    WHERE minutes_until_arrival <= 30 AND minutes_until_arrival > 0 -- we do not want predictions after bus arrived, this will create error with ln on negative values
),

minute_bins AS (
    SELECT
        key,
        extract_hour,
        extract_minute,

        -- wobble metric: https://github.com/cal-itp/data-analyses/blob/main/rt_predictions/03_prediction_inconsistency.ipynb
        -- this returns an interval type
        -- Newmark paper does absolute value between observations, but notebook decided to find the max/min per minute and
        -- set up calculation as max-min to make sure it's always positive.
        MAX(arrival_time) - MIN(arrival_time) AS prediction_spread_seconds,

        -- prediction accuracy metric: https://github.com/cal-itp/data-analyses/blob/main/rt_predictions/04_reliable_prediction_accuracy.ipynb
        AVG(prediction_seconds_difference) AS prediction_error,
        AVG(minutes_until_arrival) AS minutes_until_arrival,

        COUNTIF(is_early) AS n_predictions_early,
        COUNTIF(is_ontime) AS n_predictions_ontime,
        COUNTIF(is_late) AS n_predictions_late,

        -- stop time update completeness metric: https://github.com/cal-itp/data-analyses/blob/main/rt_predictions/01_update_completeness.ipynb
        COUNT(*) AS n_predictions_minute,

    FROM predictions_categorized
    GROUP BY key, extract_hour, extract_minute
),

derive_metrics AS (
    SELECT
        key,

        -- 04_reliable_prediction_accuracy.ipynb
        prediction_error,
        minutes_until_arrival,
        CASE
          WHEN (prediction_error >= -60 * LN(minutes_until_arrival +1.3)
                AND prediction_error <= 60* LN(minutes_until_arrival +1.5)) THEN 1
          ELSE 0
        END AS is_accurate,
        -- scaled prediction error = prediction_error_sec / seconds_to_arrival
        ROUND(SAFE_DIVIDE(prediction_error, (minutes_until_arrival * 60)), 3) AS scaled_prediction_error,

        n_predictions_early,
        n_predictions_ontime,
        n_predictions_late,

        -- 01_update_completeness.ipynb
        -- double check this, it's supposed to be fresh update, using header/vehicle_timestamp
        n_predictions_minute,
        CASE
          WHEN n_predictions_minute >= 2 THEN 1
          ELSE 0
        END AS is_complete,

        -- 03_prediction_inconsistency.ipynb.ipynb
        -- wobble: expected change means the prediction shortens with each passing minute?
        -- can this be just the prediction spread, in minutes, averaged over all the minutes?
        -- convert from prediction_spread_seconds (interval) to minutes
        (EXTRACT(DAY FROM prediction_spread_seconds) * 24 * 60 * 60
         + EXTRACT(HOUR FROM prediction_spread_seconds) * 60 * 60
         + EXTRACT(MINUTE FROM prediction_spread_seconds) * 60
         + EXTRACT(SECOND FROM prediction_spread_seconds)) / 60 AS prediction_spread_minutes,
    FROM minute_bins
),

stop_time_metrics AS (
    SELECT
        key,

        -- 04_reliable_prediction_accuracy
        ROUND(AVG(prediction_error), 2) AS avg_prediction_error_sec,
        ROUND(AVG(scaled_prediction_error), 3) AS avg_scaled_prediction_error_sec,
        SUM(is_accurate) AS n_tu_accurate_minutes,
        SUM(n_predictions_early) AS n_predictions_early,
        SUM(n_predictions_ontime) AS n_predictions_ontime,
        SUM(n_predictions_late) AS n_predictions_late,

        -- raw prediction_error per minute is used for percentile plots, bus catch likelihood, and prediction padding metrics
        ARRAY_AGG(
            ROUND(prediction_error, 2) IGNORE NULLS -- needed this, but why would this be null?
            ORDER BY minutes_until_arrival
        ) AS prediction_error_by_minute_array,
        -- we need to plot prediction_error against minutes_until_arrival
        ARRAY_AGG(
            minutes_until_arrival
            ORDER BY minutes_until_arrival DESC
        ) AS minutes_until_arrival_array,
        ARRAY_AGG(
            ROUND(scaled_prediction_error, 3) IGNORE NULLS
            ORDER BY minutes_until_arrival
        ) AS scaled_prediction_error_by_minute_array,

        -- 01_update_completeness.ipynb
        SUM(is_complete) AS n_tu_complete_minutes,
        COUNT(*) AS n_tu_minutes_available,

        -- 03_prediction_inconsistency.ipynb
        ROUND(SUM(prediction_spread_minutes), 2) AS sum_prediction_spread_minutes, -- wobble
        MAX(minutes_until_arrival) AS max_minutes_until_arrival, -- this is the denominator

        -- other derived metrics from this prediction window of 30 minutes prior
        SUM(n_predictions_minute) AS n_predictions,

    FROM derive_metrics
    GROUP BY key
),

predictions_with_trip_keys AS (
    SELECT DISTINCT
        key,
        trip_key,
        predictions_categorized.service_date,
        predictions_categorized.base64_url,
        predictions_categorized.schedule_base64_url,
        predictions_categorized.trip_id,
        predictions_categorized.trip_start_time,
        stop_id,
        stop_sequence,
        actual_arrival,
        actual_departure,

    FROM predictions_categorized
    INNER JOIN tu_trip_keys
      ON predictions_categorized.dt = tu_trip_keys.dt
      AND predictions_categorized.service_date = tu_trip_keys.service_date
      AND predictions_categorized.base64_url = tu_trip_keys.base64_url
      AND predictions_categorized.schedule_base64_url = tu_trip_keys.schedule_base64_url
      AND predictions_categorized.trip_id = tu_trip_keys.trip_id
      AND COALESCE(predictions_categorized.trip_start_time, "") = COALESCE(tu_trip_keys.trip_start_time, "")
),

fct_stop_time_metrics AS (
    SELECT
        predictions_with_trip_keys.*,
        stop_time_metrics.* EXCEPT(key)
    FROM stop_time_metrics
    INNER JOIN predictions_with_trip_keys
        USING (key)
)

SELECT * FROM fct_stop_time_metrics
