{{
    config(
        materialized='incremental',
        incremental_strategy='insert_overwrite',
        partition_by={
            'field': 'dt',
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
            'dt',
            'base64_url',
            'trip_id',
            'trip_route_id',
            'trip_direction_id',
            'trip_start_time',
            'trip_start_date',
        ]) }} as key,
        dt,
        base64_url,
        tu.num_distinct_message_ids AS tu_num_distinct_message_ids,
        tu.min_trip_update_timestamp AS tu_min_trip_update_timestamp,
        tu.max_trip_update_timestamp AS tu_max_trip_update_timestamp,
        tu.max_delay AS tu_max_delay,
        tu.num_skipped_stops AS tu_num_skipped_stops,
        vp.num_distinct_message_ids AS vp_num_distinct_message_ids,
        vp.min_trip_update_timestamp AS vp_min_trip_update_timestamp,
        vp.max_trip_update_timestamp AS vp_max_trip_update_timestamp,
    FROM trip_updates AS tu
    FULL OUTER JOIN vehicle_positions AS vp
        USING (dt, base64_url, trip_id, trip_route_id, trip_direction_id, trip_start_time, trip_start_date)
)

SELECT * FROM fct_observed_trips
