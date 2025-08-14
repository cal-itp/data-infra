{{
    config(
        materialized='incremental',
        incremental_strategy='insert_overwrite',
        partition_by = {
            'field': 'dt',
            'data_type': 'date',
            'granularity': 'day',
        },
    )
}}

WITH fct_kuba__device_properties AS(
    SELECT *
    FROM {{ ref('stg_kuba__device_properties') }}
    WHERE {{ incremental_where(default_start_var='KUBA_DEVICE_START') | trim }}
)

SELECT * FROM fct_kuba__device_properties
