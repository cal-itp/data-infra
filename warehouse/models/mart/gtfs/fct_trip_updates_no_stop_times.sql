{{
    config(
        materialized='incremental',
        incremental_strategy='insert_overwrite',
        partition_by = {
            'field': 'dt',
            'data_type': 'date',
            'granularity': 'day',
        },
        cluster_by='base64_url',
        on_schema_change='append_new_columns'
    )
}}

WITH

trip_updates AS (
    SELECT * FROM {{ ref('fct_trip_updates_messages') }}
    WHERE {{ gtfs_rt_dt_where() }}
),

fct_trip_updates_no_stop_times AS (
    SELECT * EXCEPT (stop_time_updates)
    FROM trip_updates
)

SELECT * FROM fct_trip_updates_no_stop_times
