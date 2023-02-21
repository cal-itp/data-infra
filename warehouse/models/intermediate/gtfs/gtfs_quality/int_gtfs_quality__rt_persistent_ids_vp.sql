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
    SELECT * FROM {{ ref('int_gtfs_quality__rt_feed_guideline_index_vp') }}
    {% if is_incremental() %}
    WHERE date >= EXTRACT(DATE FROM TIMESTAMP('{{ max_ts }}'))
    {% else %}
    WHERE date >= DATE_SUB(CURRENT_DATE(), INTERVAL {{ var('RT_LOOKBACK_DAYS') }} DAY)
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

daily_vehicles AS (
    SELECT dt AS date,
           base64_url,
           vehicle_id,
           COUNT(*) AS messages
      FROM fct_vehicle_positions_messages
     GROUP BY 1,2,3
),

daily_vehicles_lag AS (
    SELECT *,
           date - 1 AS prev_date,
           date + 1 AS next_date
      FROM daily_vehicles
),

vehicles_joined AS (
    SELECT COALESCE(current_day.date, prev_day.next_date) AS date,
           COALESCE(current_day.prev_date, prev_day.date) AS prev_date,
           COALESCE(current_day.base64_url, prev_day.base64_url) AS base64_url,
           current_day.vehicle_id AS id,
           prev_day.vehicle_id AS prev_id
      FROM daily_vehicles_lag AS prev_day
      FULL OUTER JOIN daily_vehicles_lag AS current_day
        ON current_day.prev_date = prev_day.date
       AND current_day.base64_url = prev_day.base64_url
       AND current_day.vehicle_id = prev_day.vehicle_id
),

vehicle_id_comparison AS (
    SELECT date,
           base64_url,
           -- Total id's in current and previous days
           COUNT(CASE WHEN id IS NOT null AND prev_id IS NOT null THEN 1 END) AS ids_both_feeds,
           -- Total id's in current feed
           COUNT(CASE WHEN id IS NOT null THEN 1 END) AS ids_current_feed,
           -- Total id's in current feed
           COUNT(CASE WHEN prev_id IS NOT null THEN 1 END) AS ids_prev_feed,
           -- New id's added
           COUNT(CASE WHEN prev_id IS null THEN 1 END) AS id_added,
           -- prev id's removed
           COUNT(CASE WHEN id IS null THEN 1 END) AS id_removed
      FROM vehicles_joined
      WHERE date IS NOT null
      AND prev_date IS NOT null
     GROUP BY 1,2
    HAVING ids_current_feed > 0
),

id_change_count AS (
    SELECT t1.date,
           t1.base64_url,
           t1.feed_type,
           MAX(t2.id_added * 100 / t2.ids_current_feed )
               OVER (
                   PARTITION BY t1.base64_url
                   ORDER BY t1.date
                   ROWS BETWEEN 30 PRECEDING AND CURRENT ROW
                    )
                AS max_percent_vehicle_ids_new
      FROM feed_guideline_index AS t1
      LEFT JOIN vehicle_id_comparison AS t2
        ON t2.base64_url = t1.base64_url
       AND t2.date = t1.date
),

int_gtfs_quality__rt_persistent_ids_vp AS (
    SELECT
        date,
        base64_url,
        feed_type,
        {{ persistent_ids_vp() }} AS check,
        {{ best_practices_alignment_rt() }} AS feature,
        CASE WHEN max_percent_vehicle_ids_new > 50 THEN "FAIL"
                ELSE "PASS"
           END AS status
    FROM id_change_count
)

SELECT * FROM int_gtfs_quality__rt_persistent_ids_vp
