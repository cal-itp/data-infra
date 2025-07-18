{{
    config(
        materialized='incremental',
        partition_by={
            'field': 'service_date',
            'data_type': 'date',
            'granularity': 'day'
        }, cluster_by=['service_date', 'base64_url']
    )
}}

WITH fct_stop_time_updates_filtered AS (
    SELECT *
    FROM {{ ref('fct_stop_time_updates') }}
    -- add extra date boundaries to grab relevant service_dates
    WHERE dt >= '2025-06-21' AND dt <= '2025-06-29'
)

SELECT * FROM fct_stop_time_updates_filtered
