WITH int_gtfs_quality__daily_assessment_candidate_entities AS (

    SELECT *
    FROM {{ ref('int_gtfs_quality__daily_assessment_candidate_entities') }}

),

int_gtfs__organization_dataset_map AS (
    -- collapse the services level
    SELECT
        date,
        organization_name,
        organization_itp_id,
        organization_source_record_id,
        organization_key,
        gtfs_dataset_key,
        gtfs_dataset_name,
        base64_url,
        schedule_feed_key,
        LOGICAL_OR(gtfs_service_data_customer_facing) AS gtfs_service_data_customer_facing,
        LOGICAL_OR(guidelines_assessed) AS guidelines_assessed,
        LOGICAL_OR(reports_site_assessed) AS reports_site_assessed
    FROM int_gtfs_quality__daily_assessment_candidate_entities
    WHERE COALESCE(organization_key, gtfs_dataset_key) IS NOT NULL
    GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9

)

SELECT * FROM int_gtfs__organization_dataset_map
