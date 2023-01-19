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
    SELECT * FROM {{ ref('int_gtfs_quality__rt_feed_guideline_index_tu') }}
    {% if is_incremental() %}
    WHERE date >= EXTRACT(DATE FROM TIMESTAMP('{{ max_ts }}'))
    {% else %}
    WHERE date >= DATE_SUB(CURRENT_DATE(), INTERVAL {{ var('TRIP_UPDATES_LOOKBACK_DAYS') }} DAY)
    {% endif %}
),

parse_outcomes AS (
    SELECT * FROM {{ ref('int_gtfs_rt__unioned_parse_outcomes') }}
    {% if is_incremental() %}
    WHERE dt >= EXTRACT(DATE FROM TIMESTAMP('{{ max_ts }}'))
    {% else %}
    WHERE dt >= DATE_SUB(CURRENT_DATE(), INTERVAL {{ var('TRIP_UPDATES_LOOKBACK_DAYS') }} DAY)
    {% endif %}
      AND feed_type = "trip_updates"
),

parse_outcomes_lag_ts AS (
  SELECT
          dt AS date,
          base64_url,
          extract_ts,
          LAG (extract_ts) OVER (PARTITION BY base64_url ORDER BY extract_ts) AS prev_extract_ts
    FROM parse_outcomes
),

daily_max_lag AS (
SELECT
      date,
      base64_url,
      MAX(DATE_DIFF(extract_ts, prev_extract_ts, SECOND)) AS max_lag
  FROM parse_outcomes_lag_ts
 GROUP BY 1,2
),

int_gtfs_quality__rt_20sec_tu AS (
    SELECT
        idx.date,
        idx.base64_url,
        idx.feed_type,
        {{ rt_20sec_tu() }} AS check,
        {{ accurate_service_data() }} AS feature,
        max_lag,
        CASE
            WHEN max_lag > 20 THEN "FAIL"
            WHEN max_lag <= 20 THEN "PASS"
        END AS status,
    FROM feed_guideline_index AS idx
    LEFT JOIN daily_max_lag AS files
           ON idx.date = files.date
          AND idx.base64_url = files.base64_url
)

SELECT * FROM int_gtfs_quality__rt_20sec_tu
