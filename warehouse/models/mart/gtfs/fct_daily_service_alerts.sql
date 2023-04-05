{{ config(
    materialized='incremental',
    incremental_strategy='insert_overwrite',
    partition_by = {
        'field': 'dt',
        'data_type': 'date',
        'granularity': 'day',
    },
) }}

WITH fct_service_alert_translations AS (
    SELECT * FROM {{ ref('fct_service_alert_translations') }}
    WHERE {{ gtfs_rt_dt_where() }}
),

select_english AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY service_alert_message_key
            ORDER BY english_likelihood DESC, header_text_language ASC) AS english_rank
    FROM fct_service_alert_translations
    QUALIFY english_rank = 1
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
        COUNT(*) AS num_appearances
    FROM select_english
    GROUP BY dt, gtfs_dataset_key, base64_url, id, cause, effect, header_text_text,
        description_text_text
)

SELECT * FROM fct_daily_service_alerts
