{{ config(
    materialized='incremental',
    incremental_strategy='insert_overwrite',
    partition_by = {
        'field': 'dt',
        'data_type': 'date',
        'granularity': 'day',
    },
) }}

{% if is_incremental() %}
    {% set dates = dbt_utils.get_column_values(table=this, column='dt', order_by = 'dt DESC', max_records = 1) %}
    {% set max_dt = dates[0] %}
{% endif %}

WITH fct_service_alerts_messages AS (
    SELECT * FROM {{ ref('fct_service_alerts_messages') }}
    {% if is_incremental() %}
    WHERE dt >= EXTRACT(DATE FROM TIMESTAMP('{{ max_dt }}'))
    {% else %}
    WHERE dt >= DATE_SUB(CURRENT_DATE(), INTERVAL {{ var('INCREMENTAL_PARTITIONS_LOOKBACK_DAYS') }} DAY)
    {% endif %}
),

fct_daily_service_alerts AS (
    SELECT
        dt,
        gtfs_dataset_key,
        base64_url,
        id,
        cause,
        effect,
        MIN(header_timestamp) AS first_header_timestamp,
        MAX(header_timestamp) AS last_header_timestamp,
        COUNT(*) AS num_appearances
    FROM fct_service_alerts_messages
    GROUP BY dt, gtfs_dataset_key, base64_url, id, cause, effect
)

SELECT * FROM fct_daily_service_alerts
