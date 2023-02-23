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
    {% set timestamps = dbt_utils.get_column_values(table=this, column='dt', order_by = 'dt DESC', max_records = 1) %}
    {% set max_dt = timestamps[0] %}
{% endif %}

WITH

int_gtfs_quality__rt_validation_outcomes AS (
    -- predicate pushdown does not seem to work through UNIONs so list these all out
    SELECT * FROM {{ ref('stg_gtfs_rt__service_alerts_validation_outcomes') }}
    {% if is_incremental() %}
    WHERE dt >= EXTRACT(DATE FROM TIMESTAMP('{{ max_dt }}'))
    {% else %}
    WHERE dt >= DATE_SUB(CURRENT_DATE(), INTERVAL {{ var('RT_LOOKBACK_DAYS') }} DAY)
    {% endif %}

    UNION ALL

    SELECT * FROM {{ ref('stg_gtfs_rt__trip_updates_validation_outcomes') }}
    {% if is_incremental() %}
    WHERE dt >= EXTRACT(DATE FROM TIMESTAMP('{{ max_dt }}'))
    {% else %}
    WHERE dt >= DATE_SUB(CURRENT_DATE(), INTERVAL {{ var('RT_LOOKBACK_DAYS') }} DAY)
    {% endif %}

    UNION ALL

    SELECT * FROM {{ ref('stg_gtfs_rt__vehicle_positions_validation_outcomes') }}
    {% if is_incremental() %}
    WHERE dt >= EXTRACT(DATE FROM TIMESTAMP('{{ max_dt }}'))
    {% else %}
    WHERE dt >= DATE_SUB(CURRENT_DATE(), INTERVAL {{ var('RT_LOOKBACK_DAYS') }} DAY)
    {% endif %}
)

SELECT * FROM int_gtfs_quality__rt_validation_outcomes
