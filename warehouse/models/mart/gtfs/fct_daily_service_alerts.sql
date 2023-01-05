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
        informed_entity_agency_id,
        informed_entity_route_id,
        informed_entity_trip_id,
        informed_entity_trip_start_time,
        informed_entity_trip_start_date,
        informed_entity_stop_id,
        active_period_start,
        active_period_end,
        cause,
        effect,
        header_text_text,
        header_text_language,
        description_text_text,
        description_text_language,
        tts_header_text_text,
        tts_header_text_language,
        tts_description_text_text,
        tts_description_text_language,
        MIN(header_timestamp) AS first_header_timestamp,
        MAX(header_timestamp) AS last_header_timestamp,
        COUNT(*) AS num_appearances
    FROM fct_service_alerts_messages
    GROUP BY dt, gtfs_dataset_key, base64_url, id, informed_entity_agency_id, informed_entity_route_id,
        informed_entity_trip_id, informed_entity_trip_start_time, informed_entity_trip_start_date,
        informed_entity_stop_id, active_period_start, active_period_end, cause, effect, header_text_text, header_text_language,
        description_text_text, description_text_language, tts_header_text_text, tts_header_text_language, tts_description_text_text,
        tts_description_text_language
)

SELECT * FROM fct_daily_service_alerts
