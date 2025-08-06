{{
    config(
        materialized='incremental',
        incremental_strategy='insert_overwrite',
        partition_by={
            'field': 'dt',
            'data_type': 'date',
            'granularity': 'day'
        }, cluster_by=['base64_url']
    )
}}

WITH stop_time_updates AS (
    SELECT *
    FROM {{ ref('test_stop_time_updates') }}
    WHERE dt >= "2025-06-23" AND dt <= "2025-06-24"
),

-- follow pattern in int_gtfs_rt__vehicle_positions_trip_day_map_grouping / fct_vehicle_locations,
-- and swap out trip key with a stop-time key.
-- trip key for fct_vehicle_locations has many locations; stop_time key for this would be used for the many predictions.
-- trip key for fct_vehicle_locations calculated first/last position; this stop_time key finds last prediction for arrival
-- group by *both* the UTC date that data was scraped (dt) *and* calculated service date
-- so that in the mart we can get just service date-level data
-- this allows us to handle the dt/service_date mismatch by grouping in two stages
grouped AS (
    SELECT DISTINCT
        stop_time_updates.dt,
        stop_time_updates.service_date,
        stop_time_updates.base64_url,
        stop_time_updates.schedule_base64_url,

        stop_time_updates.trip_id,
        stop_time_updates.trip_start_date,
        stop_time_updates.trip_start_time,

        stop_time_updates.stop_id,
        stop_time_updates.stop_sequence,

        DATETIME(TIMESTAMP_SECONDS(LAST_VALUE(arrival_time IGNORE NULLS) OVER(
            PARTITION BY base64_url, service_date, trip_id, trip_start_date, trip_start_time, stop_id, stop_sequence
            ORDER BY COALESCE(trip_update_timestamp, header_timestamp)
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING))
        ) AS last_trip_updates_arrival,
        DATETIME(TIMESTAMP_SECONDS(LAST_VALUE(departure_time IGNORE NULLS) OVER(
            PARTITION BY base64_url, service_date, trip_id, trip_start_date, trip_start_time, stop_id, stop_sequence
            ORDER BY COALESCE(trip_update_timestamp, header_timestamp)
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING))
        ) AS last_trip_updates_departure,

    FROM stop_time_updates
),

int_gtfs_rt__trip_updates_trip_stop_day_map_grouping AS (
    SELECT
       {{ dbt_utils.generate_surrogate_key([
            'service_date',
            'base64_url',
            'schedule_base64_url',
            'trip_id',
            'trip_start_time',
            'stop_id',
            'stop_sequence'
        ]) }} as key,
        dt,
        service_date,
        base64_url,
        schedule_base64_url,

        trip_id,
        trip_start_time,
        stop_id,
        stop_sequence,

        last_trip_updates_arrival,
        last_trip_updates_departure,

        -- usually one of these columns is null, but we want to use it to compare against _extract_ts
        COALESCE(last_trip_updates_arrival, last_trip_updates_departure) AS actual_arrival,
        -- get this in Pacific
        DATETIME(TIMESTAMP(COALESCE(last_trip_updates_arrival, last_trip_updates_departure)), "America/Los_Angeles") AS actual_arrival_pacific
    FROM grouped
    -- 9_540_105 left, but started with 10_000_000 ish once stop_id and stop_sequence being null are dropped
)

SELECT * FROM int_gtfs_rt__trip_updates_trip_stop_day_map_grouping
