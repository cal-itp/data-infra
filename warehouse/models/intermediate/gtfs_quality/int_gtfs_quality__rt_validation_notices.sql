{{ config(
    materialized='incremental',
    incremental_strategy='insert_overwrite',
    partition_by = {
        'field': 'dt',
        'data_type': 'date',
        'granularity': 'day',
    },
) }}

WITH

int_gtfs_quality__rt_validation_notices AS (
    -- predicate pushdown does not seem to work through UNIONs so list these all out
    SELECT * FROM {{ ref('stg_gtfs_rt__service_alerts_validation_notices') }}
    WHERE {{ incremental_where(default_start_var='PROD_GTFS_RT_START') }}

    UNION ALL

    SELECT * FROM {{ ref('stg_gtfs_rt__trip_updates_validation_notices') }}
    WHERE {{ incremental_where(default_start_var='PROD_GTFS_RT_START') }}

    UNION ALL

    SELECT * FROM {{ ref('stg_gtfs_rt__vehicle_positions_validation_notices') }}
    WHERE {{ incremental_where(default_start_var='PROD_GTFS_RT_START') }}
)

SELECT * FROM int_gtfs_quality__rt_validation_notices
