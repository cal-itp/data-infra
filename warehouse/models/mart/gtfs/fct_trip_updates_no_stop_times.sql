{{
    config(
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
        cluster_by='base64_url',
        on_schema_change='append_new_columns'
    )
}}

WITH

trip_updates AS (
    SELECT * FROM {{ ref('fct_trip_updates_messages') }}
    WHERE {{ incremental_where(default_start_var='GTFS_RT_START') }}
),

fct_trip_updates_no_stop_times AS (
    SELECT * EXCEPT (stop_time_updates)
    FROM trip_updates
)

SELECT * FROM fct_trip_updates_no_stop_times
