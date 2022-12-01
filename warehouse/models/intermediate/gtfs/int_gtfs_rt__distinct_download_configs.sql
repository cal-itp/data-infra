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

WITH

int_gtfs_rt__distinct_download_configs AS (
    -- predicate pushdown does not seem to work through UNIONs so list these all out
    SELECT DISTINCT
        dt,
        _config_extract_ts
    FROM {{ ref('stg_gtfs_rt__service_alerts_outcomes') }}
    {% if is_incremental() %}
    WHERE dt >= '{{ max_dt }}'
    {% else %}
    WHERE dt >= DATE_SUB(CURRENT_DATE(), INTERVAL {{ var('INCREMENTAL_PARTITIONS_LOOKBACK_DAYS') }} DAY)
    {% endif %}
)

SELECT * FROM int_gtfs_rt__distinct_download_configs
