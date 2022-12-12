WITH feed_guideline_index AS (
    SELECT * FROM {{ ref('int_gtfs_quality__rt_feed_guideline_index') }}
),

fct_daily_rt_feed_files AS (
    SELECT * FROM {{ ref('fct_daily_rt_feed_files') }}
),

daily_success_percent AS (
    SELECT
        base64_url,
        date,
        feed_type,
        SUM(parse_success_file_count + parse_failure_file_count) * 100 / 4320 AS percent_success
    FROM fct_daily_rt_feed_files
   GROUP BY 1, 2, 3
),

int_gtfs_quality__rt_fetch_error AS (
    SELECT
        idx.date,
        idx.base64_url,
        idx.feed_type,
        CASE WHEN idx.feed_type = 'service_alerts' THEN {{ no_fetch_error_sa() }}
             WHEN idx.feed_type = 'trip_updates' THEN {{ no_fetch_error_tu() }}
             WHEN idx.feed_type = 'vehicle_positions' THEN {{ no_fetch_error_vp() }}
        END AS check,
        {{ best_practices_alignment() }} AS feature,
        CASE
            WHEN s.percent_success >= 99 THEN "PASS"
            WHEN s.percent_success < 99 THEN "FAIL"
        END AS status,
    FROM feed_guideline_index AS idx
    LEFT JOIN daily_success_percent AS s
    ON idx.date = s.date
   AND idx.base64_url = s.base64_url
   AND idx.feed_type = s.feed_type
)

SELECT * FROM int_gtfs_quality__rt_fetch_error
