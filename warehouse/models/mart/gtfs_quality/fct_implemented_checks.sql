{{ config(materialized='table') }}

WITH

intended_checks AS (
    SELECT * FROM {{ ref('stg_gtfs_quality__intended_checks') }}
),

existing_checks AS (
    SELECT DISTINCT
        check,
        feature
    FROM {{ ref('int_gtfs_quality__guideline_checks_long') }}
),

fct_implemented_checks AS (
    SELECT
        intended.*,
        existing.check IS NOT NULL as is_implemented
    FROM intended_checks intended
    LEFT JOIN existing_checks existing
        ON intended.check = existing.check
)

SELECT * FROM fct_implemented_checks
