WITH feed_guideline_index AS (
    SELECT * FROM {{ ref('int_gtfs_quality__rt_url_guideline_index') }}
),

fct_daily_rt_feed_files AS (
    SELECT * FROM {{ ref('fct_daily_rt_feed_files') }}
),

count_files AS (
    SELECT
        base64_url,
        date,
        feed_type,
        SUM(parse_success_file_count) AS rt_files
    FROM fct_daily_rt_feed_files
   GROUP BY 1, 2, 3
),

int_gtfs_quality__rt_feeds_present AS (
    SELECT
        idx.date,
        idx.base64_url,
        idx.feed_type,
        CASE WHEN idx.feed_type = 'service_alerts' THEN {{ feed_present_service_alerts() }}
             WHEN idx.feed_type = 'trip_updates' THEN {{ feed_present_trip_updates() }}
             WHEN idx.feed_type = 'vehicle_positions' THEN {{ feed_present_vehicle_positions() }}
        END AS check,
        {{ compliance_rt() }} AS feature,
        rt_files,
        CASE
            WHEN rt_files > 0 THEN {{ guidelines_pass_status() }}
            WHEN COALESCE(rt_files, 0) = 0 THEN {{ guidelines_fail_status() }}
        END AS status,
    FROM feed_guideline_index AS idx
    LEFT JOIN count_files AS files
           ON idx.date = files.date
          AND idx.base64_url = files.base64_url
          AND idx.feed_type = files.feed_type
)

SELECT * FROM int_gtfs_quality__rt_feeds_present
