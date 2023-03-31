WITH check_cts AS (
    SELECT check, COUNT(*) AS actual_checks
    FROM {{ ref('int_gtfs_quality__guideline_checks_long') }}
    GROUP BY 1
),

idx_check_cts AS (
    SELECT check, COUNT(*) AS idx_checks
    FROM {{ ref('int_gtfs_quality__guideline_checks_index') }}
    GROUP BY 1
)

SELECT
    check,
    actual_checks,
    idx_checks
FROM check_cts
LEFT JOIN idx_check_cts
USING (check)
WHERE actual_checks != idx_checks
