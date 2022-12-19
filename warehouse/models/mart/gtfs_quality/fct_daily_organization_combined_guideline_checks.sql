{{ config(materialized='table') }}

WITH fct_daily_guideline_checks AS (
    SELECT *
    FROM {{ ref('fct_daily_guideline_checks') }}
),

fct_daily_organization_combined_guideline_checks AS (
    SELECT
        {{ dbt_utils.surrogate_key([
            'date',
            'organization_key',
            'check']) }} AS key,
        date,
        organization_name,
        feature,
        check,
        CASE
            WHEN LOGICAL_AND(NULLIF(status, "N/A") = "PASS") THEN "PASS"
            WHEN LOGICAL_AND(NULLIF(status, "N/A") = "FAIL") THEN "FAIL"
            WHEN LOGICAL_AND(status = "N/A") THEN "N/A"
        END as status,
        organization_key,
        ARRAY_AGG(DISTINCT service_name IGNORE NULLS) AS service_names_included_array,
        ARRAY_AGG(DISTINCT gtfs_dataset_name IGNORE NULLS) AS gtfs_dataset_names_included_array,
        ARRAY_AGG(DISTINCT base64_url IGNORE NULLS) AS base64_urls_included_array,
        ARRAY_AGG(DISTINCT service_key IGNORE NULLS) AS service_keys_included_array,
        ARRAY_AGG(DISTINCT gtfs_service_data_key IGNORE NULLS) AS gtfs_service_data_keys_included_array,
        ARRAY_AGG(DISTINCT gtfs_dataset_key IGNORE NULLS) AS gtfs_dataset_keys_included_array,
        ARRAY_AGG(DISTINCT schedule_feed_key IGNORE NULLS) AS schedule_feed_keys_included_array
    FROM fct_daily_guideline_checks
    GROUP BY date, organization_key, organization_name, feature, check
)

SELECT * FROM fct_daily_organization_combined_guideline_checks
