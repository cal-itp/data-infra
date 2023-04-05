{{ config(
    materialized='incremental',
    incremental_strategy='insert_overwrite',
    partition_by = {
        'field': 'dt',
        'data_type': 'date',
        'granularity': 'day',
    },
) }}

WITH service_alerts AS (
    SELECT *
    FROM {{ ref('stg_gtfs_rt__service_alerts_outcomes') }}
    WHERE {{ gtfs_rt_dt_where() }}
),

vehicle_positions AS (
    SELECT *
    FROM {{ ref('stg_gtfs_rt__vehicle_positions_outcomes') }}
    WHERE {{ gtfs_rt_dt_where() }}
),

trip_updates AS (
    SELECT *
    FROM {{ ref('stg_gtfs_rt__trip_updates_outcomes') }}
    WHERE {{ gtfs_rt_dt_where() }}
),

int_gtfs_rt__unioned_parse_outcomes AS (
    SELECT *
    FROM service_alerts
    UNION ALL
    SELECT * FROM vehicle_positions
    UNION ALL
    SELECT * FROM trip_updates
)

SELECT * FROM int_gtfs_rt__unioned_parse_outcomes
