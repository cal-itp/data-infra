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
    SELECT * FROM {{ ref('int_gtfs_quality__rt_feed_guideline_index') }}
    {% if is_incremental() %}
    WHERE date >= EXTRACT(DATE FROM TIMESTAMP('{{ max_ts }}'))
    {% else %}
    WHERE date >= DATE_SUB(CURRENT_DATE(), INTERVAL {{ var('TRIP_UPDATES_LOOKBACK_DAYS') }} DAY)
    {% endif %}
),

unioned_parse_outcomes AS (
    SELECT * FROM {{ ref('int_gtfs_rt__unioned_parse_outcomes') }}
    {% if is_incremental() %}
    WHERE dt >= EXTRACT(DATE FROM TIMESTAMP('{{ max_ts }}'))
    {% else %}
    WHERE dt >= DATE_SUB(CURRENT_DATE(), INTERVAL {{ var('TRIP_UPDATES_LOOKBACK_DAYS') }} DAY)
    {% endif %}
),

feed_ages AS (
    SELECT
        dt,
        base64_url,
        feed_type,
        COUNT(*) AS num_parses,
        MIN(TIMESTAMP_DIFF(extract_ts, last_modified_timestamp, SECOND)) AS min_feed_age,
        MAX(TIMESTAMP_DIFF(extract_ts, last_modified_timestamp, SECOND)) AS max_feed_age
    FROM unioned_parse_outcomes
    GROUP BY 1, 2, 3
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
        max_trip_update_feed_age,
        CASE
            WHEN max_trip_update_age <= 90 AND max_trip_update_feed_age <= 90 THEN {{ guidelines_pass_status() }}
            WHEN max_trip_update_age > 90 OR max_trip_update_feed_age > 90 THEN {{ guidelines_fail_status() }}
            -- If there are no trip updates for that feed for that day, result is N/A
            -- They will fail other checks for having no feed present
            WHEN max_trip_update_age IS null OR max_trip_update_feed_age IS null THEN {{ guidelines_na_check_status() }}
        END as status
    FROM feed_guideline_index AS idx
    LEFT JOIN trip_update_ages AS ages
    ON idx.date = ages.dt
        AND idx.base64_url = ages.base64_url
)

SELECT * FROM int_gtfs_quality__no_stale_trip_updates
