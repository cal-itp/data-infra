{{
    config(
        materialized='incremental',
        incremental_strategy = 'insert_overwrite',
        partition_by={
            'field': 'dt',
            'data_type': 'date',
            'granularity': 'day'
        }, cluster_by=['base64_url']
    )
}}

WITH stop_time_updates AS (
    SELECT
        dt,
        service_date,
        base64_url,
        schedule_base64_url,
        trip_id,
        trip_start_date,
        trip_start_time,
        stop_id,
        stop_sequence,

        trip_update_timestamp,
        header_timestamp,
        _extract_ts, -- this is UTC
        arrival_time,
        departure_time,

    FROM {{ ref('fct_stop_time_updates') }}
    WHERE {{ incremental_where(default_start_var='PROD_GTFS_RT_START', dev_lookback_days = 250) }}  AND trip_id IS NOT NULL AND stop_id IS NOT NULL AND stop_sequence IS NOT NULL
)

SELECT * FROM stop_time_updates
