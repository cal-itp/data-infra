{{ config(materialized='table') }}

WITH int_gtfs_quality__guideline_checks_long AS (
    SELECT *
    FROM {{ ref('int_gtfs_quality__guideline_checks_long') }}
),

fct_daily_service_combined_guideline_checks AS (
    SELECT
        {{ dbt_utils.surrogate_key([
            'date',
            'service_key',
            'check']) }} AS key,
        date,
        service_name,
        feature,
        check,
        CASE
            WHEN LOGICAL_OR(NULLIF(status, "N/A") = "FAIL") THEN "FAIL"
            WHEN LOGICAL_AND(NULLIF(status, "N/A") = "PASS") THEN "PASS"
            WHEN LOGICAL_AND(NULLIF(status, "N/A") = {{ manual_check_needed_status() }}) THEN {{ manual_check_needed_status() }}
            WHEN LOGICAL_AND(status = "N/A") THEN "N/A"
        END as status,
        service_key,
        ARRAY_AGG(DISTINCT organization_name IGNORE NULLS ORDER BY organization_name) AS organization_names_included_array,
        ARRAY_AGG(DISTINCT gtfs_dataset_name IGNORE NULLS ORDER BY gtfs_dataset_name) AS gtfs_dataset_names_included_array,
        ARRAY_AGG(DISTINCT base64_url IGNORE NULLS ORDER BY base64_url) AS base64_urls_included_array,
        ARRAY_AGG(DISTINCT organization_key IGNORE NULLS ORDER BY organization_key) AS organization_keys_included_array,
        ARRAY_AGG(DISTINCT gtfs_service_data_key IGNORE NULLS ORDER BY gtfs_service_data_key) AS gtfs_service_data_keys_included_array,
        ARRAY_AGG(DISTINCT gtfs_dataset_key IGNORE NULLS ORDER BY gtfs_dataset_key) AS gtfs_dataset_keys_included_array,
        ARRAY_AGG(DISTINCT schedule_feed_key IGNORE NULLS ORDER BY schedule_feed_key) AS schedule_feed_keys_included_array
    FROM int_gtfs_quality__guideline_checks_long
    GROUP BY date, service_key, service_name, feature, check
)

SELECT * FROM fct_daily_service_combined_guideline_checks
