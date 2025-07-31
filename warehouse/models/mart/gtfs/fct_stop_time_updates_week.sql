{{
    config(
        materialized='incremental',
        partition_by={
            'field': 'dt',
            'data_type': 'date',
            'granularity': 'day'
        }, cluster_by=['dt', 'base64_url']
    )
}}

WITH fct_stop_time_updates_filtered AS (
    SELECT *
    FROM {{ ref('fct_stop_time_updates') }}
    -- add extra date boundaries to grab relevant service_dates
    WHERE dt = '2025-06-21'
)

SELECT * FROM fct_stop_time_updates_filtered
