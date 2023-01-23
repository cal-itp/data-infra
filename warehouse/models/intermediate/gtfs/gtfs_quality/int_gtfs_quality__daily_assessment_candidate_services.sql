{{ config(materialized='table') }}

WITH daily_assessment_candidate_entities AS (
    SELECT * FROM {{ ref('int_gtfs_quality__daily_assessment_candidate_entities') }}
),

int_gtfs_quality__daily_assessment_candidate_services AS (
    SELECT EXTRACT(DATE FROM tu.date) AS date,
           tu.service_key,
           tu.base64_url AS tu_base_64_url,
           vp.base64_url AS vp_base_64_url
      FROM daily_assessment_candidate_entities tu
      JOIN daily_assessment_candidate_entities vp
        ON vp.date = tu.date
       AND vp.service_key = tu.service_key
     WHERE tu.gtfs_dataset_type = "trip_updates"
       AND vp.gtfs_dataset_type = "vehicle_positions"
)

SELECT * FROM int_gtfs_quality__daily_assessment_candidate_services
