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

int_gtfs_rt__distinct_download_configs AS (
    -- predicate pushdown does not seem to work through UNIONs so list these all out
    SELECT DISTINCT
        dt,
        _config_extract_ts
    FROM {{ ref('stg_gtfs_rt__service_alerts_outcomes') }}
    WHERE {{ incremental_where(default_start_var='PROD_GTFS_RT_START') }}
)

SELECT * FROM int_gtfs_rt__distinct_download_configs
