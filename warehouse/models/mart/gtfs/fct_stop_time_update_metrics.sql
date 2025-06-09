WITH fct_stop_time_updates AS (
    SELECT *
    FROM {{ ref('fct_stop_time_updates_with_arrivals') }}
),

prediction_difference AS (
    SELECT
        base64_url,
        service_date,
        trip_id,
        stop_id,
        _extract_ts,
        actual_arrival_utc,
        extract_hour,
        extract_minute,
        DATETIME_DIFF(actual_arrival, arrival_time, SECOND) AS prediction_seconds_difference,
        DATETIME_DIFF(actual_arrival, _extract_ts, MINUTE) as minutes_until_arrival,
    FROM fct_stop_time_updates
),

prediction_difference_by_minute AS (
    SELECT
        base64_url,
        service_date,
        trip_id,
        stop_id,
        extract_hour,
        extract_minute,
        AVG(prediction_seconds_difference) AS prediction_error,
        AVG(minutes_until_arrival) AS minutes_until_arrival,
        COUNT(*) AS n_predictions_minute,

  FROM prediction_difference
  WHERE ABS(minutes_until_arrival) <= 30 AND _extract_ts <= actual_arrival
  GROUP BY base64_url, service_date, trip_id, stop_id, extract_hour, extract_minute
),

prediction_error_bounds_and_completeness AS (
    SELECT
        base64_url,
        service_date,
        trip_id,
        stop_id,
        minutes_until_arrival,
        prediction_error,
        -60 * LN(minutes_until_arrival +1.3) AS lower_bound, --04_reliable_prediction_accuracy.ipynb
        60* LN(minutes_until_arrival +1.5) AS upper_bound,
        n_predictions_minute,
        CASE
          WHEN n_predictions_minute >= 2 THEN 1
          ELSE 0
        END AS is_complete,
    -- expected change means the prediction shortens with each passing minute?
    FROM prediction_difference_by_minute
),

prediction_accuracy AS (
    SELECT
        base64_url,
        service_date,
        trip_id,
        stop_id,
        minutes_until_arrival,
        CASE
          WHEN prediction_error >= lower_bound AND prediction_error <= upper_bound THEN 1
          ELSE 0
        END AS is_accurate,
        prediction_error,
        is_complete,
        n_predictions_minute,
  FROM prediction_error_bounds_and_completeness
),

stop_time_metrics AS (
    -- TODO: can this table be combined with other CTEs?
    SELECT
        base64_url,
        service_date,
        trip_id,
        stop_id,
        SUM(is_accurate) AS n_accurate_minutes,
        SUM(is_complete) AS n_complete_minutes,
        COUNT(*) AS n_minute_bins,
        AVG(prediction_error) AS avg_prediction_error_sec,
        SUM(n_predictions_minute) AS n_predictions,

    FROM prediction_accuracy
    GROUP BY base64_url, service_date, trip_id, stop_id
)

SELECT * FROM stop_time_metrics
