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
    SELECT * FROM {{ ref('int_gtfs_quality__rt_feed_guideline_index_sa') }}
    {% if is_incremental() %}
    WHERE date >= EXTRACT(DATE FROM TIMESTAMP('{{ max_ts }}'))
    {% else %}
    WHERE date >= DATE_SUB(CURRENT_DATE(), INTERVAL {{ var('RT_LOOKBACK_DAYS') }} DAY)
    {% endif %}
),

stg_gtfs_rt__service_alerts AS (
    SELECT * FROM {{ ref('stg_gtfs_rt__service_alerts') }}
    {% if is_incremental() %}
    WHERE dt >= EXTRACT(DATE FROM TIMESTAMP('{{ max_ts }}'))
    {% else %}
    WHERE dt >= DATE_SUB(CURRENT_DATE(), INTERVAL {{ var('RT_LOOKBACK_DAYS') }} DAY)
    {% endif %}
),

service_alert_ages AS (
    SELECT
        dt,
        base64_url,
        COUNT(*) AS num_service_alerts,
        -- I'm not sure what timestamp to use for service alerts - I don't even understand yet how this check applies to service alerts
        MIN(TIMESTAMP_DIFF(_extract_ts, TIMESTAMP_SECONDS(active.start), SECOND)) AS min_service_alert_age,
        PERCENTILE_CONT(TIMESTAMP_DIFF(_extract_ts, TIMESTAMP_SECONDS(active.start), SECOND), 0.5) AS median_service_alert_age,
        MAX(TIMESTAMP_DIFF(_extract_ts, TIMESTAMP_SECONDS(active.start), SECOND)) AS max_service_alert_age,
    FROM stg_gtfs_rt__service_alerts, UNNEST(active_period) AS active
    GROUP BY 1, 2
),

int_gtfs_quality__no_stale_service_alerts AS (
    SELECT
        idx.date,
        idx.base64_url,
        idx.feed_type,
        {{ no_stale_service_alerts() }} AS check,
        {{ best_practices_alignment_rt() }} AS feature,
        min_service_alert_age,
        max_service_alert_age,
        CASE
            WHEN max_service_alert_age <= 600 THEN "PASS"
            WHEN max_service_alert_age > 600 THEN "FAIL"
            -- If there are no service_alerts for that feed for that day, result is N/A
            -- They will fail other checks for having no feed present
            WHEN max_service_alert_age IS null THEN "N/A"
        END as status
    FROM feed_guideline_index AS idx
    LEFT JOIN service_alert_ages AS ages
    ON idx.date = ages.dt
        AND idx.base64_url = ages.base64_url
)

SELECT * FROM int_gtfs_quality__no_stale_service_alerts
