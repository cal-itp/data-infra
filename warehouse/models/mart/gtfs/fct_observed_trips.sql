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

service_alerts AS (
    SELECT * FROM {{ ref('int_gtfs_rt__service_alerts_trip_summaries') }}
),

fct_observed_trips AS (
    SELECT
        {{ dbt_utils.surrogate_key([
            'dt',
            'associated_schedule_gtfs_dataset_key',
            'trip_id',
            'trip_route_id',
            'trip_direction_id',
            'trip_start_time',
            'trip_start_date',
        ]) }} as key,
        dt,
        ,
        tu.num_distinct_message_ids AS tu_num_distinct_message_ids,
        tu.min_trip_update_timestamp AS tu_min_trip_update_timestamp,
        tu.max_trip_update_timestamp AS tu_max_trip_update_timestamp,
        tu.max_delay AS tu_max_delay,
        tu.num_skipped_stops AS tu_num_skipped_stops,
        vp.num_distinct_message_ids AS vp_num_distinct_message_ids,
        vp.min_trip_update_timestamp AS vp_min_trip_update_timestamp,
        vp.max_trip_update_timestamp AS vp_max_trip_update_timestamp,
        sa.num_distinct_message_ids AS sa_num_distinct_message_ids,
        sa.service_alert_message_keys AS sa_service_alert_message_key,
    FROM fct_daily_rt_feed_files AS ff
    LEFT JOIN dim_provider_gtfs_data AS pgd
        ON ff.gtfs_dataset_key =
    -- in RT world can use associated_schedule_gtfs_dataset_key
    FULL OUTER JOIN trip_updates AS tu
        ON ff.date = tu.dt
        AND
    FROM trip_updates AS tu
    LEFT JOIN fct_daily_rt_feed_files AS tu
    FULL OUTER JOIN vehicle_positions AS vp
        ON tu.dt = vp.du
        AND tu.provider_gtfs_data = vp.provider_gtfs_data
        AND tu.trip_id = vp.trip_id
        AND tu.trip_route_id = vp.trip_route_id
        AND tu.trip_direction_id = vp.trip_direction_id
        AND tu.trip_start_time = vp.trip_start_time
        AND tu.trip_start_date = vp.trip_start_date
    FULL OUTER JOIN service_alerts AS sa
        ON tu.dt = sa.du
        AND tu.provider_gtfs_data = sa.provider_gtfs_data
        AND tu.trip_id = sa.trip_id
        AND tu.trip_route_id = sa.trip_route_id
        AND tu.trip_direction_id = sa.trip_direction_id
        AND tu.trip_start_time = sa.trip_start_time
        AND tu.trip_start_date = sa.trip_start_date
)

SELECT * FROM fct_observed_trips
