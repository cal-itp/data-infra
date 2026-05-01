{{ config(
    materialized='incremental',
    incremental_strategy='microbatch',
    event_time = 'dt',
    batch_size = 'day',
    begin=var('GTFS_RT_START'),
    lookback=var('DBT_ALL_INCREMENTAL_LOOKBACK_DAYS'),
    partition_by = {
        'field': 'dt',
        'data_type': 'date',
        'granularity': 'day',
    },
    full_refresh=false,
)
}}

WITH

int_gtfs_rt__distinct_download_configs AS (
    -- predicate pushdown does not seem to work through UNIONs so list these all out
    SELECT DISTINCT
        dt,
        _config_extract_ts
    FROM {{ ref('stg_gtfs_rt__service_alerts_outcomes') }}
)

SELECT * FROM int_gtfs_rt__distinct_download_configs
