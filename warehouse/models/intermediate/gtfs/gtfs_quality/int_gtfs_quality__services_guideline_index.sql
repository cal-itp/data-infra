{{ config(materialized='ephemeral') }}

WITH daily_assessment_candidate_entities AS (
    SELECT * FROM {{ ref('int_gtfs_quality__daily_assessment_candidate_entities') }}
),

-- we never want results from the current date, as data will be incomplete
int_gtfs_quality__service_guideline_index AS (
    SELECT DISTINCT
        EXTRACT(DATE FROM date) AS date,
        service_key,
    FROM daily_assessment_candidate_entities
    WHERE date < CURRENT_DATE
)

SELECT * FROM int_gtfs_quality__service_guideline_index
