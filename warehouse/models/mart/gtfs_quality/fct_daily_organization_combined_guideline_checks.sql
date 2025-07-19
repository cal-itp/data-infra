{{ config(materialized='table') }}

WITH int_gtfs_quality__guideline_checks_long AS (
    SELECT *
    FROM {{ ref('int_gtfs_quality__guideline_checks_long') }}
    WHERE organization_key IS NOT NULL AND public_customer_facing_fixed_route
),

fct_daily_organization_combined_guideline_checks AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key([
            'date',
            'organization_key',
            'check']) }} AS key,
        date,
        organization_name,
        feature,
        check,
        is_manual,
        reports_order,
        {{ guidelines_aggregation_logic() }} as status,
        {{ guidelines_aggregation_logic_reports() }} as reports_status,
        -- The overall percentage was calculated earlier and is identical across all services for a given organization.
        AVG(percentage) AS percentage,
        organization_key,
        organization_source_record_id,
        ARRAY_AGG(DISTINCT service_name IGNORE NULLS ORDER BY service_name) AS service_names_included_array,
        ARRAY_AGG(DISTINCT gtfs_dataset_name IGNORE NULLS ORDER BY gtfs_dataset_name) AS gtfs_dataset_names_included_array,
        ARRAY_AGG(DISTINCT base64_url IGNORE NULLS ORDER BY base64_url) AS base64_urls_included_array,
        ARRAY_AGG(DISTINCT service_key IGNORE NULLS ORDER BY service_key) AS service_keys_included_array,
        ARRAY_AGG(DISTINCT gtfs_service_data_key IGNORE NULLS ORDER BY gtfs_service_data_key) AS gtfs_service_data_keys_included_array,
        ARRAY_AGG(DISTINCT gtfs_dataset_key IGNORE NULLS ORDER BY gtfs_dataset_key) AS gtfs_dataset_keys_included_array,
        ARRAY_AGG(DISTINCT schedule_feed_key IGNORE NULLS ORDER BY schedule_feed_key) AS schedule_feed_keys_included_array,
        ARRAY_AGG(percentage IGNORE NULLS) AS percentage_included_array
    FROM int_gtfs_quality__guideline_checks_long
    GROUP BY date, organization_key, organization_source_record_id, organization_name, feature, check, is_manual, reports_order
)

SELECT * FROM fct_daily_organization_combined_guideline_checks
