{{
    config(
        materialized='incremental',
        incremental_strategy='insert_overwrite',
        partition_by={
            'field': 'service_date',
            'data_type': 'date',
            'granularity': 'day'
        }, cluster_by=['service_date', 'base64_url']
    )
}}


WITH fct_stop_time_updates AS (
    SELECT
        base64_url,
        service_date,
        trip_id,
        trip_start_date,
        trip_start_time,
        stop_id,
        stop_sequence,
        _extract_ts, -- this is UTC
        --trip_update_timestamp,
        --header_timestamp,
        arrival_time,
        departure_time,
    FROM {{ ref('fct_stop_time_updates_week') }}
    WHERE service_date >= '2025-06-22' AND service_date <= '2025-06-28'
),

fct_stop_arrivals AS (
    SELECT DISTINCT
        base64_url,
        service_date,
        trip_id,
        stop_id,
        stop_sequence,
        actual_arrival_pacific,
        actual_arrival,

    FROM {{ ref('fct_stop_time_arrivals_week') }}
    WHERE service_date >= '2025-06-22' AND service_date <= '2025-06-28'
),

stop_times_with_arrivals AS (
    SELECT
        tu.base64_url,
        tu.service_date,
        tu.trip_id,
        tu.trip_start_date,
        tu.trip_start_time,
        tu.stop_id,
        tu.stop_sequence,
        tu._extract_ts,
        EXTRACT(HOUR FROM tu._extract_ts) AS extract_hour,
        EXTRACT(MINUTE FROM tu._extract_ts) AS extract_minute,
        DATETIME(TIMESTAMP_SECONDS(tu.arrival_time)) AS arrival_time, -- turn posix time into UTC
        DATETIME(TIMESTAMP_SECONDS(tu.departure_time)) AS departure_time, -- turn posix time into UTC

        arrivals.actual_arrival_pacific,
        arrivals.actual_arrival,

    FROM fct_stop_time_updates as tu
    INNER JOIN fct_stop_arrivals as arrivals
        USING (base64_url, service_date, trip_id, stop_id, stop_sequence)
      -- removed the trip_start_date/time from this and it merged better?
      -- with trip_start_date/time, somehow the merge dropped all the rows (incremental tables loaded locally?)
)

SELECT * FROM stop_times_with_arrivals
