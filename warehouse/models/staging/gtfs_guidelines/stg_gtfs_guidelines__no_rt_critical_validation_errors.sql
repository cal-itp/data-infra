WITH feed_guideline_index AS (
    SELECT * FROM {{ ref('stg_gtfs_guidelines__feed_guideline_index') }}
    WHERE check = {{ no_rt_critical_validation_errors() }}
),

-- It's called "hourly" but if you use the "file_count_day" it's a daily table
gtfs_rt_fact_files_wide_daily AS (
SELECT * FROM {{ ref('gtfs_rt_fact_files_wide_hourly') }}
),

gtfs_rt_fact_daily_validation_errors AS (
    SELECT * FROM {{ ref('gtfs_rt_fact_daily_validation_errors') }}
),

gtfs_rt_validation_code_descriptions AS (
    SELECT * FROM {{ ref('gtfs_rt_validation_code_descriptions') }}
),

rt_files_by_day AS (
    SELECT
        calitp_itp_id,
        calitp_url_number,
        date_extracted AS date,
        COUNT(*) AS rt_files
    FROM gtfs_rt_fact_files_wide_daily
    GROUP BY 1,2,3
),

errors_by_day AS (
    SELECT
        t1.feed_key,
        t1.date,
        SUM(t1.occurrences) AS errors
    FROM gtfs_rt_fact_daily_validation_errors AS t1
    LEFT JOIN gtfs_rt_validation_code_descriptions AS t2
         ON t1.error_id = t2.code
    WHERE t2.is_critical = "y"
    GROUP BY t1.feed_key, t1.date
),

errors_daily_check AS (
    SELECT
        t1.date,
        t1.calitp_itp_id,
        t1.calitp_url_number,
        t1.calitp_agency_name,
        t1.check,
        t1.feature,
        t2.rt_files,
        t3.errors,
        CASE
            WHEN rt_files > 0 AND errors IS null THEN "PASS"
            WHEN rt_files IS null THEN "FAIL"
            WHEN errors > 0 THEN "FAIL"
        END AS status,
    FROM feed_guideline_index AS t1
    LEFT JOIN rt_files_by_day AS t2
         ON t1.calitp_itp_id = t2.calitp_itp_id
         AND t1.calitp_url_number = t2.calitp_url_number
         AND t1.date = t2.date
    LEFT JOIN errors_by_day AS t3
         ON t1.feed_key = t3.feed_key
         AND t1.date = t3.date
)

SELECT * FROM errors_daily_check
