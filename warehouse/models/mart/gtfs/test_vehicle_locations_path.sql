{{
    config(
        materialized='incremental',
        incremental_strategy='insert_overwrite',
        partition_by = {
            'field': 'service_date',
            'data_type': 'date',
            'granularity': 'day',
        },
        cluster_by=['service_date', 'base64_url', 'pt_array'],
        on_schema_change='append_new_columns'
    )
}}

WITH fct_vehicle_locations_path AS (
    SELECT
        * EXCEPT(pt_array),
        ST_MAKELINE(pt_array) AS pt_array,
    --FROM {{ ref('fct_vehicle_locations_path') }}
    FROM `cal-itp-data-infra.mart_gtfs.fct_vehicle_locations_path`
    WHERE service_date >= '2025-06-22' AND service_date <= '2025-06-28'
)


SELECT * FROM fct_vehicle_locations_path
