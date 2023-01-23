{{
    config(
        materialized='incremental',
        incremental_strategy='insert_overwrite',
        partition_by={
            'field': 'date',
            'data_type': 'date',
            'granularity': 'day',
        },
        cluster_by='base64_url',
    )
}}

WITH trip_updates AS (
    SELECT * FROM {{ ref('int_gtfs_rt__trip_updates_summaries') }}
),

vehicle_positions AS (
    SELECT * FROM {{ ref('int_gtfs_rt__vehicle_positions_trip_summaries') }}
),

fct_observed_trips AS (
    SELECT
        {{ dbt_utils.surrogate_key([
            'date',
            'base64_url',
            'trip_id',
            'trip_route_id',
            'trip_direction_id',
            'trip_start_time',
            'trip_start_date',
        ]) }} as key,
        tu.* EXCEPT (key),
        vp.* EXCEPT (key),
    FROM trip_updates tu
    FULL OUTER JOIN vehicle_positions vp
        USING (date, base64_url, trip_id, trip_route_id, trip_direction_id, trip_start_time, trip_start_date)
)

SELECT * FROM fct_observed_trips
