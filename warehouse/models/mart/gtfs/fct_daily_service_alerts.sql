{{ config(
    materialized='incremental',
    incremental_strategy='insert_overwrite',
    partition_by = {
        'field': 'dt',
        'data_type': 'date',
        'granularity': 'day',
    },
) }}

WITH fct_service_alerts_messages_unnested AS (
    SELECT * FROM {{ ref('fct_service_alerts_messages_unnested') }}
    WHERE {{ gtfs_rt_dt_where() }}
),

fct_daily_service_alerts AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['dt', 'base64_url', 'id', 'header_text_text']) }} AS key,
        dt,
        gtfs_dataset_key,
        base64_url,
        id,
        cause,
        effect,
        header_text_text,
        description_text_text,
        MIN(header_timestamp) AS first_header_timestamp,
        MAX(header_timestamp) AS last_header_timestamp,
        COUNT(DISTINCT service_alert_message_key) AS num_appearances
    FROM fct_service_alerts_messages_unnested
    GROUP BY dt, gtfs_dataset_key, base64_url, id, cause, effect, header_text_text,
        description_text_text
)

SELECT * FROM fct_daily_service_alerts
