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
    -- Description for code E003:
    ---- "All trip_ids provided in the GTFS-rt feed must exist in the GTFS data, unless the schedule_relationship is ADDED"
    WHERE code = "E003"
    GROUP BY 1, 2
),

int_gtfs_quality__trip_id_alignment AS (
    SELECT
        idx.date,
        idx.base64_url,
        idx.feed_type,
        {{ trip_id_alignment() }} AS check,
        {{ fixed_route_completeness() }} AS feature,
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

SELECT * FROM int_gtfs_quality__trip_id_alignment
