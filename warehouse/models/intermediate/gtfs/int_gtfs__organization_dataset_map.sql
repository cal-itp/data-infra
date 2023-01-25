WITH int_gtfs_quality__daily_assessment_candidate_entities AS (

    SELECT *
    FROM {{ ref('int_gtfs_quality__daily_assessment_candidate_entities') }}

),

int_gtfs__organization_dataset_map AS (
    -- collapse the services level
    SELECT DISTINCT
        date,
        organization_name,
        organization_itp_id,
        organization_source_record_id,
        organization_key,
        gtfs_dataset_key,
        gtfs_dataset_name,
        schedule_feed_key,
        gtfs_service_data_customer_facing,
        base64_url,
        guidelines_assessed,
        reports_site_assessed
    FROM int_gtfs_quality__daily_assessment_candidate_entities
),

SELECT * FROM int_gtfs__organization_dataset_map
