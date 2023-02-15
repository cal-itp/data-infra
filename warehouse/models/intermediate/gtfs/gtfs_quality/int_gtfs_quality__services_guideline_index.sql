{{ config(materialized='ephemeral') }}

WITH daily_assessment_candidate_entities AS (
    SELECT * FROM {{ ref('int_gtfs_quality__daily_assessment_candidate_entities') }}
),

-- we never want results from the current date, as data will be incomplete
int_gtfs_quality__service_guideline_index AS (
    SELECT DISTINCT
        date,
        service_key,
    FROM daily_assessment_candidate_entities
    WHERE date < CURRENT_DATE
    -- Since this is the earliest date in fct_observed_trips, it's the earliest date we currently need
    -- This filter resolves some duplication issues that appear in dim_services up until Nov '22
      AND date >= '2022-12-17'
)

SELECT * FROM int_gtfs_quality__service_guideline_index
