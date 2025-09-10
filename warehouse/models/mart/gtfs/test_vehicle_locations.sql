{{
    config(
        materialized='incremental',
        incremental_strategy='insert_overwrite',
        partition_by = {
            'field': 'dt',
            'data_type': 'date',
            'granularity': 'day',
        },
        cluster_by=['dt', 'base64_url', 'location'],
        on_schema_change='append_new_columns'
    )
}}

WITH fct_vehicle_locations AS (
    SELECT *
    --FROM {{ ref('fct_vehicle_locations') }}
    FROM `cal-itp-data-infra.mart_gtfs.fct_vehicle_locations`
    WHERE service_date >= '2025-06-22' AND service_date <= '2025-06-28'
)


SELECT * FROM fct_vehicle_locations
