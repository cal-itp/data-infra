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

trip_updates AS (
    SELECT * FROM {{ ref('fct_trip_updates_messages') }}
    {% if is_incremental() %}
    WHERE dt >= '{{ max_dt }}'
    {% else %}
    WHERE dt >= DATE_SUB(CURRENT_DATE(), INTERVAL {{ var('TRIP_UPDATES_LOOKBACK_DAYS') }} DAY)
    {% endif %}
),

int_gtfs_rt__trip_updates_summaries AS (
    SELECT * EXCEPT (stop_time_updates)
    FROM trip_updates
)

SELECT * FROM int_gtfs_rt__trip_updates_summaries
