{{ config(materialized='table') }}

WITH int_gtfs_quality__daily_assessment_candidate_entities AS (

    SELECT *
    FROM {{ ref('int_gtfs_quality__daily_assessment_candidate_entities') }}

),

int_gtfs_quality__organization_dataset_map AS (
    -- collapse the services level
    SELECT
        date,
        organization_name,
        organization_itp_id,
        organization_source_record_id,
        organization_key,
        gtfs_dataset_key,
        gtfs_dataset_name,
        gtfs_dataset_type,
        base64_url,
        schedule_feed_key,
        LOGICAL_OR(gtfs_service_data_customer_facing) AS gtfs_service_data_customer_facing,
        LOGICAL_OR(public_customer_facing_fixed_route) AS public_customer_facing_fixed_route,
        LOGICAL_OR(public_customer_facing_or_regional_subfeed_fixed_route) AS public_customer_facing_or_regional_subfeed_fixed_route
    FROM int_gtfs_quality__daily_assessment_candidate_entities
    -- TODO: maybe we can/should make this an AND? not sure if having rows where one is null is useful
    WHERE COALESCE(organization_key, gtfs_dataset_key) IS NOT NULL
    GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10

)

SELECT * FROM int_gtfs_quality__organization_dataset_map
