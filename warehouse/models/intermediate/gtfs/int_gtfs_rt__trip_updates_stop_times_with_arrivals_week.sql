{{
    config(
        materialized='incremental',
        incremental_strategy='insert_overwrite',
        partition_by={
            'field': 'service_date',
            'data_type': 'date',
            'granularity': 'day'
        }, cluster_by=['service_date', 'base64_url']
    )
}}

WITH stop_times_with_arrivals_week AS (
    SELECT *
    FROM {{ ref('int_gtfs_rt__trip_updates_stop_times_with_arrivals') }}
    WHERE service_date >= '2025-06-22' AND service_date <= '2025-06-28'
)

SELECT * FROM stop_times_with_arrivals_week
