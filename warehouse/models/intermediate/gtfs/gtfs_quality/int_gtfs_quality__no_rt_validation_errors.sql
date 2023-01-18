WITH feed_guideline_index AS (
    SELECT * FROM {{ ref('int_gtfs_quality__rt_feed_guideline_index') }}
),

fct_daily_rt_feed_files AS (
    SELECT * FROM {{ ref('fct_daily_rt_feed_files') }}
),

fct_daily_rt_feed_validation_notices AS (
    SELECT * FROM {{ ref('fct_daily_rt_feed_validation_notices') }}
),

count_files AS (
    SELECT
        base64_url,
        date,
        SUM(parse_success_file_count) AS rt_files
    FROM fct_daily_rt_feed_files
    GROUP BY 1, 2
),

errors AS (
    SELECT
        date,
        base64_url,
        SUM(total_notices) AS total_errors,
    FROM fct_daily_rt_feed_validation_notices
    -- All error codes start with the letter E (warnings start with W)
    WHERE code LIKE "E%"
    GROUP BY 1, 2
),

int_gtfs_quality__no_rt_validation_errors AS (
    SELECT
        idx.date,
        idx.base64_url,
        idx.feed_type,
        {{ no_rt_validation_errors() }} AS check,
        {{ compliance_rt() }} AS feature,
        rt_files,
        total_errors,
        CASE
            WHEN rt_files IS NOT NULL AND COALESCE(total_errors, 0) = 0 THEN "PASS" -- files present and no errors
            WHEN rt_files IS NOT NULL AND total_errors > 0 THEN "FAIL" -- files present and there are errors
        END AS status,
    FROM feed_guideline_index AS idx
    LEFT JOIN count_files AS files
    ON idx.date = files.date
        AND idx.base64_url = files.base64_url
    LEFT JOIN errors
    ON idx.date = errors.date
        AND idx.base64_url = errors.base64_url
)

SELECT * FROM int_gtfs_quality__no_rt_validation_errors
