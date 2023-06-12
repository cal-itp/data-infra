{{ config(
    materialized='incremental',
    incremental_strategy='insert_overwrite',
    partition_by = {
        'field': 'dt',
        'data_type': 'date',
        'granularity': 'day',
    },
) }}

WITH fct_vehicle_locations AS (
    SELECT * FROM {{ ref('fct_vehicle_locations') }}
    WHERE {{ incremental_where(default_start_var='PROD_GTFS_RT_START') }}
),

fct_daily_vehicle_location_trip_counts AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['dt', 'base64_url']) }} AS key,
        dt,
        gtfs_dataset_key,
        base64_url,
        COUNT(DISTINCT trip_id) AS distinct_trips_observed
    FROM fct_vehicle_locations
    GROUP BY dt, gtfs_dataset_key, base64_url
)

SELECT * FROM fct_daily_vehicle_location_trip_counts
