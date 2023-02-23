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

vehicle_positions AS (
    SELECT * FROM {{ ref('stg_gtfs_rt__vehicle_positions') }}
    {% if is_incremental() %}
    WHERE dt >= EXTRACT(DATE FROM TIMESTAMP('{{ max_ts }}'))
    {% else %}
    WHERE dt >= DATE_SUB(CURRENT_DATE(), INTERVAL {{ var('RT_LOOKBACK_DAYS') }} DAY)
    {% endif %}
),

lag_ts AS (
  SELECT
          dt AS date,
          base64_url,
          header_timestamp,
          LAG(header_timestamp) OVER(PARTITION BY base64_url ORDER BY header_timestamp) AS prev_header_timestamp
    FROM vehicle_positions
),

-- Note that since the header_timestamp will repeat when it hasn't been updated, the DATE_DIFF will be 0 seconds for some.
-- This would affect us if we were measuring the AVG(), but it doesn't since we're only looking at MAX()
daily_max_lag AS (
SELECT
      date,
      base64_url,
      MAX(DATE_DIFF(header_timestamp, prev_header_timestamp, SECOND)) AS max_lag
  FROM lag_ts
 GROUP BY 1, 2
),

int_gtfs_quality__rt_20sec_vp AS (
    SELECT
        idx.date,
        idx.base64_url,
        idx.feed_type,
        {{ rt_20sec_vp() }} AS check,
        {{ accurate_service_data() }} AS feature,
        max_lag,
        CASE
            WHEN max_lag > 20 THEN {{ guidelines_fail_status() }}
            WHEN max_lag <= 20 THEN {{ guidelines_pass_status() }}
        END AS status,
    FROM feed_guideline_index AS idx
    LEFT JOIN daily_max_lag AS files
           ON idx.date = files.date
          AND idx.base64_url = files.base64_url
)

SELECT * FROM int_gtfs_quality__rt_20sec_vp
