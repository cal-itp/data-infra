WITH

intended_checks AS (
    SELECT * FROM {{ ref('stg_gtfs_guidelines__intended_checks_v2')}}
),

existing_checks AS (
    SELECT DISTINCT
        code,
        feature
    FROM {{ ref('fct_daily_guideline_checks') }}
)

fct_implemented_checks AS (
    SELECT
        intended.*,
        existing.code IS NOT NULL as is_implemented
    FROM intended_checks intended
    LEFT JOIN existing_checks existing
        ON intended.code = existing.code
)

SELECT * FROM fct_implemented_checks
