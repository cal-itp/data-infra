{{ config(
    materialized='incremental',
    incremental_strategy='microbatch',
    event_time = 'dt',
    batch_size = 'day',
    begin=var('GTFS_RT_START'),
    lookback=var('DBT_ALL_MICROBATCH_LOOKBACK_DAYS'),
    partition_by = {
        'field': 'dt',
        'data_type': 'date',
        'granularity': 'day',
    },
    full_refresh=false,
)
}}

WITH

int_gtfs_quality__rt_validation_notices AS (

    SELECT * FROM {{ ref('stg_gtfs_rt__service_alerts_validation_notices') }}

    UNION ALL

    SELECT * FROM {{ ref('stg_gtfs_rt__trip_updates_validation_notices') }}

    UNION ALL

    SELECT * FROM {{ ref('stg_gtfs_rt__vehicle_positions_validation_notices') }}
)

SELECT * FROM int_gtfs_quality__rt_validation_notices
