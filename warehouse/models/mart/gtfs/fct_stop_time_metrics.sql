{{
    config(
        materialized='incremental',
        incremental_strategy = 'insert_overwrite',
        unique_key = 'key',
        partition_by={
            'field': 'service_date',
            'data_type': 'date',
            'granularity': 'day'
        }, cluster_by=['service_date', 'base64_url']
    )
}}

WITH arrivals AS (
    SELECT
        key,
        dt,
        service_date,
        base64_url,
        schedule_base64_url,
        trip_id,
        trip_start_time,
        stop_id,
        stop_sequence,
        actual_arrival
    FROM {{ ref('int_gtfs_rt__trip_updates_trip_stop_day_map_grouping') }}
    WHERE dt >= "2025-06-23" AND dt <= "2025-06-24"
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

    FROM `cal-itp-data-infra.staging.int_gtfs_rt__trip_updates_trip_day_map_grouping`
    WHERE dt >= "2025-06-23" AND dt <= "2025-06-24"
    --{{ ref('int_gtfs_rt__trip_updates_trip_day_map_grouping') }}
),

trip_updates AS (
    SELECT
        dt,
        service_date,
        base64_url,
        schedule_base64_url,
        trip_id,
        trip_start_time,
        stop_id,
        stop_sequence,

        _extract_ts,
        arrival_time,
        departure_time
    FROM {{ ref('test_stop_time_updates') }}
    WHERE dt >= "2025-06-23" AND dt <= "2025-06-24"
),

trip_updates2 AS (
    SELECT
        * EXCEPT(_extract_ts, arrival_time, departure_time),

        DATETIME(tu._extract_ts) AS _extract_ts,
        EXTRACT(HOUR FROM tu._extract_ts) AS extract_hour,
        EXTRACT(MINUTE FROM tu._extract_ts) AS extract_minute,
        DATETIME(TIMESTAMP_SECONDS(tu.arrival_time)) AS arrival_time, -- turn posix time into UTC
        DATETIME(TIMESTAMP_SECONDS(tu.departure_time)) AS departure_time,
    FROM trip_updates as tu
),

prediction_difference AS (
    SELECT
        arrivals.key,
        tu2.trip_id,

        tu2.extract_hour,
        tu2.extract_minute,

        tu2.arrival_time, -- this is null
        arrivals.actual_arrival, -- this is blank, this is why keys don't match

        DATETIME_DIFF(arrivals.actual_arrival, tu2.arrival_time, SECOND) AS prediction_seconds_difference,
        DATETIME_DIFF(arrivals.actual_arrival, tu2._extract_ts, MINUTE) as minutes_until_arrival,

    FROM trip_updates2 as tu2
    INNER JOIN arrivals
        ON tu2.dt = arrivals.dt
        AND tu2.base64_url = arrivals.base64_url
        AND tu2.service_date = arrivals.service_date
        AND tu2.schedule_base64_url = arrivals.schedule_base64_url
        AND tu2.trip_id = arrivals.trip_id
        -- this is how fct_vehicle_locations is handled
        -- this is often null but we need to include it for frequency based trips
        AND COALESCE(tu2.trip_start_time, "") = COALESCE(arrivals.trip_start_time, "")
        AND tu2.stop_id = arrivals.stop_id
        AND tu2.stop_sequence = arrivals.stop_sequence
    WHERE tu2._extract_ts <= arrivals.actual_arrival AND DATETIME_DIFF(arrivals.actual_arrival, tu2._extract_ts, MINUTE) <= 30
),

minute_bins AS (
    SELECT
        key,
        extract_hour,
        extract_minute,

        -- wobble metric: https://github.com/cal-itp/data-analyses/blob/main/rt_predictions/03_prediction_inconsistency.ipynb
        -- this returns an interval type
        MAX(arrival_time) - MIN(arrival_time) AS prediction_spread_seconds,

        -- prediction accuracy metric: https://github.com/cal-itp/data-analyses/blob/main/rt_predictions/04_reliable_prediction_accuracy.ipynb
        AVG(prediction_seconds_difference) AS prediction_error,
        AVG(minutes_until_arrival) AS minutes_until_arrival,

        -- stop time update completeness metric: https://github.com/cal-itp/data-analyses/blob/main/rt_predictions/01_update_completeness.ipynb
        COUNT(*) AS n_predictions_minute,

    FROM prediction_difference
    -- filter out predictions more than 30 minutes before bus arrives at stop
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

-- should this be joined back with key to get base64_url, etc?
stop_time_metrics AS (
    SELECT
        key,

        -- 04_reliable_prediction_accuracy
        AVG(prediction_error) AS avg_prediction_error_sec,
        SUM(is_accurate) AS n_tu_accurate_minutes,

        -- 01_update_completeness.ipynb
        SUM(is_complete) AS n_tu_complete_minutes,
        COUNT(*) AS n_tu_minutes_available,

        -- 03_prediction_inconsistency.ipynb
        SUM(prediction_spread_minutes) / COUNT(*) AS avg_prediction_spread_minutes, -- wobble

        -- other derived metrics from this prediction window of 30 minutes prior
        SUM(n_predictions_minute) AS n_predictions,

    FROM derive_metrics
    GROUP BY key
),

fct_stop_time_metrics AS (
    SELECT
        arrivals.key,
        tu_trip_keys.trip_key,
        arrivals.dt,
        arrivals.service_date,
        arrivals.base64_url,
        arrivals.schedule_base64_url,
        arrivals.trip_id,
        arrivals.trip_start_time,
        arrivals.stop_id,
        arrivals.stop_sequence,

        arrivals.actual_arrival,
        stop_time_metrics.avg_prediction_error_sec,
        stop_time_metrics.n_tu_accurate_minutes,
        stop_time_metrics.n_tu_complete_minutes,
        stop_time_metrics.n_tu_minutes_available,
        stop_time_metrics.avg_prediction_spread_minutes,
        stop_time_metrics.n_predictions

    FROM arrivals
    INNER JOIN stop_time_metrics USING (key)
    INNER JOIN tu_trip_keys
        ON arrivals.dt = tu_trip_keys.dt
        AND arrivals.service_date = tu_trip_keys.service_date
        AND arrivals.base64_url = tu_trip_keys.base64_url
        AND arrivals.schedule_base64_url = tu_trip_keys.schedule_base64_url
        AND arrivals.trip_id = tu_trip_keys.trip_id
        AND arrivals.trip_start_time = tu_trip_keys.trip_start_time
)

SELECT * FROM fct_stop_time_metrics
