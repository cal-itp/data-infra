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
    WHERE date >= DATE_SUB(CURRENT_DATE(), INTERVAL {{ var('RT_LOOKBACK_DAYS') }} DAY)
    {% endif %}
),

stg_gtfs_rt__trip_updates AS (
    SELECT * FROM {{ ref('stg_gtfs_rt__trip_updates') }}
    {% if is_incremental() %}
    WHERE dt >= EXTRACT(DATE FROM TIMESTAMP('{{ max_ts }}'))
    {% else %}
    WHERE dt >= DATE_SUB(CURRENT_DATE(), INTERVAL {{ var('RT_LOOKBACK_DAYS') }} DAY)
    {% endif %}
),

trip_update_ages AS (
    SELECT
        dt,
        base64_url,
        COUNT(*) AS num_trip_updates,
        MIN(TIMESTAMP_DIFF(_extract_ts, trip_update_timestamp, SECOND)) AS min_trip_update_age,
        PERCENTILE_CONT(TIMESTAMP_DIFF(_extract_ts, trip_update_timestamp, SECOND), 0.5) AS median_trip_update_age,
        MAX(TIMESTAMP_DIFF(_extract_ts, trip_update_timestamp, SECOND)) AS max_trip_update_age,
    FROM stg_gtfs_rt__trip_updates
    GROUP BY 1, 2
),

int_gtfs_quality__no_stale_trip_updates AS (
    SELECT
        idx.date,
        idx.base64_url,
        idx.feed_type,
        {{ no_stale_trip_updates() }} AS check,
        {{ best_practices_alignment_rt() }} AS feature,
        min_trip_update_age,
        max_trip_update_age,
        CASE
            WHEN max_trip_update_age <= 90 THEN "PASS"
            WHEN max_trip_update_age > 90 THEN "FAIL"
            -- If there are no trip updates for that feed for that day, result is N/A
            -- They will fail other checks for having no feed present
            WHEN max_trip_update_age IS null THEN "N/A"
        END as status
    FROM feed_guideline_index AS idx
    LEFT JOIN trip_update_ages AS ages
    ON idx.date = ages.dt
        AND idx.base64_url = ages.base64_url
)

SELECT * FROM int_gtfs_quality__no_stale_trip_updates
