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
    FROM {{ ref('fct_stop_time_updates') }}
    WHERE {{ incremental_where(default_start_var='PROD_GTFS_RT_START') }} AND dt >= "2025-06-01"
),

prediction_arrays AS (
    SELECT
        service_date,
        base64_url,

        trip_id,
        trip_start_time,

        stop_id,
        stop_sequence,

        ARRAY_AGG(DATETIME(_extract_ts)
            ORDER BY _extract_ts
        ) AS _extract_ts_array,

        -- will this be problematic? typically arrival_time is provided but not departure_time
        -- we don't want to have any nulls for arrays to work
        ARRAY_AGG(
            COALESCE(DATETIME(TIMESTAMP_SECONDS(arrival_time)), DATETIME(TIMESTAMP_SECONDS(departure_time)))
            ORDER BY _extract_ts
        ) AS arrival_time_array,

        -- departure_time is often null, but when we don't have it, we will set it to arrival_time anyway
        -- IGNORE NULLS can't be used with this OVER and PARTITION BY combination
        -- BQ errors: Analytic function array_agg does not support IGNORE NULLS or RESPECT NULLS.
        ARRAY_AGG(
            COALESCE(DATETIME(TIMESTAMP_SECONDS(departure_time)), DATETIME(TIMESTAMP_SECONDS(arrival_time)))
            ORDER BY _extract_ts
        ) AS departure_time_array,

    FROM stop_time_updates
    WHERE (arrival_time IS NOT NULL OR departure_time IS NOT NULL) -- filter out where both columns are NULL, can't capture prediction
    GROUP BY base64_url, service_date, trip_id, trip_start_time, stop_id, stop_sequence
),

-- follow pattern in int_gtfs_rt__vehicle_positions_trip_day_map_grouping / fct_vehicle_locations,
-- and swap out trip key with a stop-time key.
-- trip key for fct_vehicle_locations has many locations; stop_time key for this would be used for the many predictions.
-- trip key for fct_vehicle_locations calculated first/last position; this stop_time key finds last prediction for arrival
-- group by *both* the UTC date that data was scraped (dt) *and* calculated service date
-- so that in the mart we can get just service date-level data
-- this allows us to handle the dt/service_date mismatch by grouping in two stages
arrivals AS (
    SELECT DISTINCT
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
        key,
        arrivals.dt,
        arrivals.service_date,
        arrivals.base64_url,
        arrivals.schedule_base64_url,

        arrivals.trip_id,
        arrivals.trip_start_time,
        arrivals.stop_id,
        arrivals.stop_sequence,

        _extract_ts_array,
        arrival_time_array,
        departure_time_array,
        last_trip_updates_arrival,
        last_trip_updates_departure,

        -- usually one of these columns is null, but we want to use it to compare against _extract_ts
        COALESCE(last_trip_updates_arrival, last_trip_updates_departure) AS actual_arrival,
        GREATEST(COALESCE(last_trip_updates_arrival, last_trip_updates_departure)) AS actual_departure,
        -- get this in Pacific
        DATETIME(TIMESTAMP(COALESCE(last_trip_updates_arrival, last_trip_updates_departure)), "America/Los_Angeles") AS actual_arrival_pacific,
        DATETIME(TIMESTAMP(GREATEST(COALESCE(last_trip_updates_arrival, last_trip_updates_departure))), "America/Los_Angeles") AS actual_departure_pacific,

    FROM arrivals
    INNER JOIN prediction_arrays
        ON arrivals.service_date = prediction_arrays.service_date
        AND arrivals.base64_url = prediction_arrays.base64_url
        AND arrivals.trip_id = prediction_arrays.trip_id
        -- including trip_start_date prevents joins, and since we can group earlier with service_date, this is ok
        -- this is how fct_vehicle_locations is handled
        -- this is often null but we need to include it for frequency based trips
        AND COALESCE(arrivals.trip_start_time, "") = COALESCE(prediction_arrays.trip_start_time, "")
        AND arrivals.stop_id = prediction_arrays.stop_id
        AND arrivals.stop_sequence = prediction_arrays.stop_sequence
)

SELECT * FROM int_gtfs_rt__trip_updates_trip_stop_day_map_grouping
