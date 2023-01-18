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

vehicle_position_ages AS (
    SELECT
        dt,
        base64_url,
        COUNT(*) AS num_vehicle_positions,
        MIN(TIMESTAMP_DIFF(_extract_ts, vehicle_timestamp, SECOND)) AS min_vehicle_position_age,
        PERCENTILE_CONT(TIMESTAMP_DIFF(_extract_ts, vehicle_timestamp, SECOND), 0.5) AS median_vehicle_position_age,
        MAX(TIMESTAMP_DIFF(_extract_ts, vehicle_timestamp, SECOND)) AS max_vehicle_position_age,
        MAX(TIMESTAMP_DIFF(_extract_ts, header_timestamp, SECOND)) AS max_vehicle_position_feed_age,
    FROM fct_vehicle_positions_messages
    GROUP BY 1, 2
),

int_gtfs_quality__no_stale_vehicle_positions AS (
    SELECT
        idx.date,
        idx.base64_url,
        idx.feed_type,
        {{ no_stale_vehicle_positions() }} AS check,
        {{ best_practices_alignment_rt() }} AS feature,
        min_vehicle_position_age,
        max_vehicle_position_age,
        max_vehicle_position_feed_age,
        CASE
            WHEN max_vehicle_position_age <= 90 AND max_vehicle_position_feed_age <= 90 THEN "PASS"
            WHEN max_vehicle_position_age > 90 OR max_vehicle_position_feed_age > 90 THEN "FAIL"
            -- If there are no vehicle position updates for that feed for that day, result is N/A
            -- They will fail other checks for having no feed present
            WHEN max_vehicle_position_age IS null OR max_vehicle_position_feed_age IS null THEN "N/A"
        END as status
    FROM feed_guideline_index AS idx
    LEFT JOIN vehicle_position_ages AS ages
    ON idx.date = ages.dt
        AND idx.base64_url = ages.base64_url
)

SELECT * FROM int_gtfs_quality__no_stale_vehicle_positions
