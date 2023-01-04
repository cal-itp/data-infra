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
    {% set timestamps = dbt_utils.get_column_values(table=this, column='dt', order_by = 'dt DESC', max_records = 1) %}
    {% set max_ts = timestamps[0] %}
{% endif %}

WITH

feed_guideline_index AS (
    SELECT * FROM {{ ref('int_gtfs_quality__rt_feed_guideline_index_vp') }}
),

stg_gtfs_rt__vehicle_positions AS (
    SELECT * FROM {{ ref('stg_gtfs_rt__vehicle_positions') }}
    {% if is_incremental() %}
    WHERE dt >= EXTRACT(DATE FROM TIMESTAMP('{{ max_ts }}'))
    {% else %}
    WHERE dt >= DATE_SUB(CURRENT_DATE(), INTERVAL {{ var('INCREMENTAL_PARTITIONS_LOOKBACK_DAYS') }} DAY)
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
    FROM stg_gtfs_rt__vehicle_positions
    GROUP BY 1, 2
),

int_gtfs_quality__no_stale_vehicle_positions AS (
    SELECT
        idx.date,
        idx.base64_url,
        idx.feed_type,
        {{ no_stale_vehicle_positions() }} AS check,
        {{ up_to_dateness() }} AS feature,
        min_vehicle_position_age,
        max_vehicle_position_age,
        CASE
            WHEN max_vehicle_position_age <= 90 THEN "PASS"
            WHEN max_vehicle_position_age > 90 THEN "FAIL"
        END as status
    FROM feed_guideline_index AS idx
    LEFT JOIN vehicle_position_ages AS ages
    ON idx.date = ages.dt
        AND idx.base64_url = ages.base64_url
)

SELECT * FROM int_gtfs_quality__no_stale_vehicle_positions
