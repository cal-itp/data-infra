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
    {% set max_ts = timestamps[0] %}
{% endif %}

WITH service_alerts AS (
    SELECT *
    FROM {{ ref('stg_gtfs_rt__service_alerts_outcomes') }}
    {% if is_incremental() %}
    WHERE dt >= EXTRACT(DATE FROM TIMESTAMP('{{ max_ts }}'))
    {% else %}
    WHERE dt >=  {{ var('GTFS_RT_START') }}
    {% endif %}
),

vehicle_positions AS (
    SELECT *
    FROM {{ ref('stg_gtfs_rt__vehicle_positions_outcomes') }}
    {% if is_incremental() %}
    WHERE dt >= EXTRACT(DATE FROM TIMESTAMP('{{ max_ts }}'))
    {% else %}
    WHERE dt >=  {{ var('GTFS_RT_START') }}
    {% endif %}
),

trip_updates AS (
    SELECT *
    FROM {{ ref('stg_gtfs_rt__trip_updates_outcomes') }}
    {% if is_incremental() %}
    WHERE dt >= EXTRACT(DATE FROM TIMESTAMP('{{ max_ts }}'))
    {% else %}
    WHERE dt >=  {{ var('GTFS_RT_START') }}
    {% endif %}
),

int_gtfs_rt__unioned_parse_outcomes AS (
    SELECT *
    FROM service_alerts
    UNION ALL
    SELECT * FROM vehicle_positions
    UNION ALL
    SELECT * FROM trip_updates
)

SELECT * FROM int_gtfs_rt__unioned_parse_outcomes
