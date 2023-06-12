{{ config(
    materialized='incremental',
    incremental_strategy='insert_overwrite',
    partition_by = {
        'field': 'dt',
        'data_type': 'date',
        'granularity': 'day',
    },
) }}

WITH fct_stop_time_updates AS (
    SELECT * FROM {{ ref('fct_trip_updates_no_stop_times') }}
    WHERE {{ incremental_where(default_start_var='PROD_GTFS_RT_START') }}
),

fct_daily_trip_update_status_counts AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['dt', 'base64_url', 'trip_schedule_relationship']) }} AS key,
        dt,
        base64_url,
        trip_schedule_relationship,
        gtfs_dataset_key,
        COUNT(DISTINCT trip_id) AS distinct_trip_ids,
    FROM fct_stop_time_updates
    GROUP BY 1, 2, 3, 4, 5
)

SELECT * FROM fct_daily_trip_update_status_counts
