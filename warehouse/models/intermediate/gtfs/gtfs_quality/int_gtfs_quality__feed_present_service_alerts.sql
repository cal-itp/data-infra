WITH feed_guideline_index AS (
    SELECT * FROM {{ ref('int_gtfs_quality__rt_feed_guideline_index') }}
     WHERE feed_type = 'service_alerts'
),

fct_daily_rt_feed_files AS (
    SELECT * FROM {{ ref('fct_daily_rt_feed_files') }}
),

count_files AS (
    SELECT
        base64_url,
        date,
        SUM(parse_success_file_count) AS rt_files
    FROM fct_daily_rt_feed_files
   WHERE feed_type = 'service_alerts'
   GROUP BY 1, 2
),

int_gtfs_quality__feed_present_service_alerts AS (
    SELECT
        idx.date,
        idx.base64_url,
        idx.feed_type,
        {{ feed_present_service_alerts() }} AS check,
        {{ compliance() }} AS feature,
        rt_files,
        CASE
            WHEN rt_files > 0 THEN "PASS"
            WHEN rt_files = 0 THEN "FAIL"
        END AS status,
    FROM feed_guideline_index AS idx
    LEFT JOIN count_files AS files
    ON idx.date = files.date
        AND idx.base64_url = files.base64_url
)

SELECT * FROM int_gtfs_quality__feed_present_service_alerts
