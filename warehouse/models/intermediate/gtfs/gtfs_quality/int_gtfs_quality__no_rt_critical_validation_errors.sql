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

critical_notices AS (
    SELECT
        date,
        base64_url,
        SUM(total_notices) AS errors,
    FROM fct_daily_rt_feed_validation_notices
    WHERE is_critical
    GROUP BY 1, 2
),

int_gtfs_quality__no_rt_critical_validation_errors AS (
    SELECT
        idx.date,
        idx.base64_url,
        idx.feed_type,
        {{ no_rt_critical_validation_errors() }} AS check,
        {{ compliance() }} AS feature,
        rt_files,
        errors,
        CASE
            WHEN COALESCE(errors, 0) = 0 THEN "PASS"
            WHEN rt_files IS NOT NULL THEN "FAIL" -- we had no errors, but did have files
        END AS status,
    FROM feed_guideline_index AS idx
    LEFT JOIN count_files AS files
    ON idx.date = files.date
        AND idx.base64_url = files.base64_url
    LEFT JOIN critical_notices AS notices
    ON idx.date = notices.date
        AND idx.base64_url = notices.base64_url
)

SELECT * FROM int_gtfs_quality__no_rt_critical_validation_errors
