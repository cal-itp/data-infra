WITH daily_feed_checks AS (
    SELECT * FROM {{ ref('fct_daily_feed_guideline_checks') }}
),

intended_checks AS (
    SELECT * FROM {{ ref('stg_gtfs_quality__intended_checks') }}
),

rows_not_matching_count AS (
    SELECT
        date,
        feed_key,
        COUNT(*) AS checks,
    FROM daily_feed_checks
    GROUP BY 1, 2
    HAVING COUNT(*) != (SELECT COUNT(*) FROM intended_checks)
)


SELECT * FROM rows_not_matching_count
