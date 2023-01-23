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

feed_guideline_index AS (
    SELECT * FROM {{ ref('int_gtfs_quality__daily_assessment_candidate_services') }}
    {% if is_incremental() %}
    WHERE date >= EXTRACT(DATE FROM TIMESTAMP('{{ max_ts }}'))
    {% else %}
    WHERE date >= DATE_SUB(CURRENT_DATE(), INTERVAL {{ var('RT_LOOKBACK_DAYS') }} DAY)
    {% endif %}
),

trip_updates_summaries AS (
    SELECT * FROM {{ ref('int_gtfs_rt__trip_updates_summaries') }}
    {% if is_incremental() %}
    WHERE dt >= EXTRACT(DATE FROM TIMESTAMP('{{ max_ts }}'))
    {% else %}
    -- Using the longer RT_LOOKBACK_DAYS rather than TRIP_UPDATES_LOOKBACK_DAYS
    -- This should be OK since we're using the more-efficient trip_updates_summaries table
    WHERE dt >= DATE_SUB(CURRENT_DATE(), INTERVAL {{ var('RT_LOOKBACK_DAYS') }} DAY)
    {% endif %}
),

fct_vehicle_positions_messages AS (
    SELECT * FROM {{ ref('fct_vehicle_positions_messages') }}
    {% if is_incremental() %}
    WHERE dt >= EXTRACT(DATE FROM TIMESTAMP('{{ max_ts }}'))
    {% else %}
    WHERE dt >= DATE_SUB(CURRENT_DATE(), INTERVAL {{ var('RT_LOOKBACK_DAYS') }} DAY)
    {% endif %}
),

daily_trip_update_trips AS (
    SELECT DISTINCT
          dt AS date,
          base64_url,
          trip_id,
          trip_schedule_relationship
    FROM trip_updates_summaries
),

daily_vehicle_position_trips AS (
    SELECT DISTINCT
          dt AS date,
          base64_url,
          trip_id
    FROM fct_vehicle_positions_messages
),

joined AS (
    SELECT s.service_key,
           s.date,
           tu.trip_id AS tu_trip_id,
           vp.trip_id AS vp_trip_id
      FROM feed_guideline_index s
      JOIN daily_trip_update_trips tu
        ON tu.date = s.date
       AND tu.base64_url = s.tu_base_64_url
      LEFT JOIN daily_vehicle_position_trips vp
        ON vp.date = s.date
       AND vp.base64_url = s.vp_base_64_url
),

int_gtfs_quality__all_tu_in_vp AS (
    SELECT service_key,
           date,
           {{ all_tu_in_vp() }} AS check,
           {{ fixed_route_completeness() }} AS feature,
            CASE WHEN COUNT(CASE WHEN vp_trip_id IS NOT null THEN 1 END) * 1.0 / COUNT(*) = 1 THEN "PASS"
                 ELSE "FAIL"
            END AS status,
      FROM joined
     GROUP BY 1,2
)

SELECT * FROM int_gtfs_quality__all_tu_in_vp
