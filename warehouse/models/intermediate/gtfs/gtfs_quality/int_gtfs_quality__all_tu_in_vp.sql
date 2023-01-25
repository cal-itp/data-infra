{{ config(
    materialized='incremental',
    incremental_strategy='insert_overwrite',
    partition_by = {
        'field': 'date',
        'data_type': 'date',
        'granularity': 'day',
    },
) }}

{% if is_incremental() %}
    {% set timestamps = dbt_utils.get_column_values(table=this, column='date', order_by = 'date DESC', max_records = 1) %}
    {% set max_ts = timestamps[0] %}
{% endif %}

WITH

services_guideline_index AS (
    SELECT * FROM {{ ref('int_gtfs_quality__services_guideline_index') }}
    {% if is_incremental() %}
    WHERE date >= EXTRACT(DATE FROM TIMESTAMP('{{ max_ts }}'))
    {% else %}
    WHERE date >= DATE_SUB(CURRENT_DATE(), INTERVAL {{ var('TRIP_UPDATES_LOOKBACK_DAYS') }} DAY)
    {% endif %}
),

dim_provider_gtfs_data AS (
    SELECT * FROM {{ ref('dim_provider_gtfs_data') }}
),

trip_updates_summaries AS (
    SELECT * FROM {{ ref('int_gtfs_rt__trip_updates_summaries') }}
    {% if is_incremental() %}
    WHERE dt >= EXTRACT(DATE FROM TIMESTAMP('{{ max_ts }}'))
    {% else %}
    WHERE dt >= DATE_SUB(CURRENT_DATE(), INTERVAL {{ var('TRIP_UPDATES_LOOKBACK_DAYS') }} DAY)
    {% endif %}
),

fct_vehicle_positions_messages AS (
    SELECT * FROM {{ ref('fct_vehicle_positions_messages') }}
    {% if is_incremental() %}
    WHERE dt >= EXTRACT(DATE FROM TIMESTAMP('{{ max_ts }}'))
    {% else %}
    WHERE dt >= DATE_SUB(CURRENT_DATE(), INTERVAL {{ var('TRIP_UPDATES_LOOKBACK_DAYS') }} DAY)
    {% endif %}
),

daily_trip_update_trips AS (
    SELECT
        dt AS date,
        gtfs_dataset_key,
        trip_id
    FROM trip_updates_summaries
   WHERE trip_schedule_relationship IN ("SCHEDULED","CANCELED”,“ADDED")
   GROUP BY 1,2,3
),

daily_vehicle_position_trips AS (
    SELECT
        dt AS date,
        gtfs_dataset_key,
        trip_id
    FROM fct_vehicle_positions_messages
    GROUP BY 1,2,3
),

joined AS (
    SELECT
       idx.date,
       idx.service_key,
       tu.trip_id AS tu_trip_id,
       vp.trip_id AS vp_trip_id
    FROM services_guideline_index AS idx
    LEFT JOIN dim_provider_gtfs_data AS quartet
    ON idx.service_key = quartet.service_key
    AND idx.date BETWEEN EXTRACT(DATE FROM quartet._valid_from) AND EXTRACT(DATE FROM quartet._valid_to)
    LEFT JOIN daily_trip_update_trips tu
    ON tu.date = idx.date
    AND tu.gtfs_dataset_key = quartet.trip_updates_gtfs_dataset_key
    LEFT JOIN daily_vehicle_position_trips vp
    ON vp.date = idx.date
    AND vp.gtfs_dataset_key = quartet.vehicle_positions_gtfs_dataset_key
),

int_gtfs_quality__all_tu_in_vp AS (
    SELECT service_key,
           date,
           {{ all_tu_in_vp() }} AS check,
           {{ fixed_route_completeness() }} AS feature,
            CASE WHEN COUNT(CASE WHEN vp_trip_id IS NOT null AND tu_trip_id IS NOT null THEN 1 END) * 1.0 / NULLIF(COUNT(CASE WHEN tu_trip_id IS NOT null THEN 1 END),0) = 1 THEN "PASS"
                 ELSE "FAIL"
            END AS status,
      FROM joined
     GROUP BY 1,2,3,4
)

SELECT * FROM int_gtfs_quality__all_tu_in_vp
