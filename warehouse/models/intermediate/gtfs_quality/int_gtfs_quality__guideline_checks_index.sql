{{ config(materialized='table') }}

WITH checks AS (
    SELECT *
    FROM {{ ref('stg_gtfs_quality__intended_checks') }}
),

assessment_candidates AS (
    SELECT *
    FROM {{ ref('int_gtfs_quality__daily_assessment_candidate_entities') }}
),

int_gtfs_quality__guideline_checks_index AS (
    SELECT
        key,
        date,
        organization_name,
        service_name,
        gtfs_dataset_name,
        gtfs_dataset_type,
        check,
        feature,
        entity,

        organization_source_record_id,
        service_source_record_id,
        gtfs_service_data_source_record_id,
        gtfs_dataset_source_record_id,

        guidelines_assessed,
        reports_site_assessed,
        organization_assessed,
        service_assessed,
        gtfs_service_data_assessed,

        organization_itp_id,
        organization_hubspot_company_record_id,
        organization_ntd_id,

        gtfs_service_data_customer_facing,
        gtfs_service_data_category,
        regional_feed_type,
        backdated_regional_feed_type,
        use_subfeed_for_reports,
        agency_id,
        route_id,
        network_id,

        base64_url,
        had_rt_files,

        organization_key,
        service_key,
        gtfs_service_data_key,
        gtfs_dataset_key,
        schedule_feed_key,
        schedule_to_use_for_rt_validation_gtfs_dataset_key

    FROM assessment_candidates
    CROSS JOIN checks
)

SELECT * FROM int_gtfs_quality__guideline_checks_index
