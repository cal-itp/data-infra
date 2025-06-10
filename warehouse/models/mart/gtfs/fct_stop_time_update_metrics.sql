{{
    config(
        partition_by = {
            'field': 'service_date',
            'data_type': 'date',
            'granularity': 'day',
        },
        cluster_by='base64_url',
    )
}}

WITH fct_stop_time_updates AS (
    SELECT *
    FROM {{ ref('fct_stop_time_updates_with_arrivals') }}
),

fct_tu_summaries AS (
    SELECT DISTINCT
        trip_instance_key,
        service_date,
        base64_url,
        schedule_base64_url,
        trip_id
    FROM {{ ref('fct_trip_updates_summaries') }}
),

prediction_difference AS (
    SELECT
        base64_url,
        service_date,
        trip_id,
        stop_id,
        stop_sequence,
        DATETIME(_extract_ts) AS _extract_ts,
        arrival_time,
        actual_arrival,
        extract_hour,
        extract_minute,
        DATETIME_DIFF(actual_arrival, arrival_time, SECOND) AS prediction_seconds_difference,
        DATETIME_DIFF(actual_arrival, DATETIME(_extract_ts), MINUTE) as minutes_until_arrival,
    FROM fct_stop_time_updates
    WHERE DATETIME(_extract_ts) <= actual_arrival
    -- filter out the times we ask for predictions after bus has arrived
),

minute_bins AS (
    SELECT
        base64_url,
        service_date,
        trip_id,
        stop_id,
        stop_sequence,
        extract_hour,
        extract_minute,

        -- wobble metric: https://github.com/cal-itp/data-analyses/blob/main/rt_predictions/03_prediction_inconsistency.ipynb
        MAX(arrival_time) - MIN(arrival_time) AS prediction_spread_seconds,

        -- prediction accuracy metric: https://github.com/cal-itp/data-analyses/blob/main/rt_predictions/04_reliable_prediction_accuracy.ipynb
        AVG(prediction_seconds_difference) AS prediction_error,
        AVG(minutes_until_arrival) AS minutes_until_arrival,

        -- stop time update completeness metric: https://github.com/cal-itp/data-analyses/blob/main/rt_predictions/01_update_completeness.ipynb
        COUNT(*) AS n_predictions_minute,

    FROM prediction_difference
    -- filter out predictions more than 30 minutes before bus arrives at stop
    WHERE ABS(minutes_until_arrival) <= 30
    GROUP BY base64_url, service_date, trip_id, stop_id, stop_sequence, extract_hour, extract_minute
),

derive_metrics AS (
    SELECT
        base64_url,
        service_date,
        trip_id,
        stop_id,
        stop_sequence,

        -- 04_reliable_prediction_accuracy.ipynb
        prediction_error,
        minutes_until_arrival,
        CASE
          WHEN (prediction_error >= -60 * LN(minutes_until_arrival +1.3)
                AND prediction_error <= 60* LN(minutes_until_arrival +1.5)) THEN 1
          ELSE 0
        END AS is_accurate,

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
        prediction_spread_seconds / 60 AS prediction_spread_minutes,
    FROM minute_bins
),

stop_time_metrics AS (
    -- TODO: can this table be combined with other CTEs?
    SELECT
        base64_url,
        service_date,
        trip_id,
        stop_id,
        stop_sequence,

        -- 04_reliable_prediction_accuracy
        AVG(prediction_error) AS avg_prediction_error_sec,
        SUM(is_accurate) AS n_accurate_minutes,

        -- 01_update_completeness.ipynb
        SUM(is_complete) AS n_complete_minutes,
        COUNT(*) AS n_minute_bins,

        -- 03_prediction_inconsistency.ipynb
        SUM(prediction_spread_minutes) / COUNT(*) AS avg_prediction_spread, -- wobble

        -- other derived metrics from this prediction window of 30 minutes prior
        SUM(n_predictions_minute) AS n_predictions,

    FROM derive_metrics
    GROUP BY base64_url, service_date, trip_id, stop_id, stop_sequence
),

fct_stop_time_metrics AS (
    SELECT
        stop_time_metrics.*,
        fct_tu_summaries.trip_instance_key,
        fct_tu_summaries.schedule_base64_url
    FROM stop_time_metrics
    LEFT JOIN fct_tu_summaries -- inner join has left us with zero rows before, is this because of incremental settings?
        ON stop_time_metrics.service_date = fct_tu_summaries.service_date
        AND stop_time_metrics.base64_url = fct_tu_summaries.base64_url
        AND stop_time_metrics.trip_id = fct_tu_summaries.trip_id
)

SELECT * FROM fct_stop_time_metrics
