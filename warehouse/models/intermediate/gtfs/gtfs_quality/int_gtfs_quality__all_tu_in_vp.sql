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

provider_guideline_index AS (
    SELECT * FROM {{ ref('fct_daily_provider_gtfs_data') }}
    {% if is_incremental() %}
    WHERE date >= EXTRACT(DATE FROM TIMESTAMP('{{ max_ts }}'))
    {% else %}
    WHERE date >= DATE_SUB(CURRENT_DATE(), INTERVAL {{ var('TRIP_UPDATES_LOOKBACK_DAYS') }} DAY)
    {% endif %}
),

dim_gtfs_datasets AS (
    SELECT * FROM {{ ref('dim_gtfs_datasets') }}
)

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
        base64_url,
        trip_id
    FROM trip_updates_summaries
   WHERE trip_schedule_relationship IN ("SCHEDULED","CANCELED”,“ADDED")
   GROUP BY 1,2,3
),

daily_vehicle_position_trips AS (
    SELECT
        dt AS date,
        base64_url,
        trip_id
    FROM fct_vehicle_positions_messages
    GROUP BY 1,2,3
),

joined AS (
    SELECT p.service_key,
           p.date,
           tu.trip_id AS tu_trip_id,
           vp.trip_id AS vp_trip_id
      FROM provider_guideline_index p
      LEFT JOIN dim_gtfs_datasets tud
        ON d.key = p.trip_updates_gtfs_dataset_key
      LEFT JOIN daily_trip_update_trips tu
        ON tu.date = p.date
       AND tu.base64_url = tud.base_64_url
      LEFT JOIN dim_gtfs_datasets vpd
        ON d.key = p.vehicle_positions_gtfs_dataset_key
      LEFT JOIN daily_vehicle_position_trips vp
        ON vp.date = p.date
       AND vp.base64_url = vpd.vp_base_64_url
       AND vp.trip_id = tu.trip_id
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
