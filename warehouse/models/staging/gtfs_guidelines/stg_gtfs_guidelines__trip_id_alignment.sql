WITH feed_guideline_index AS (
    SELECT * FROM {{ ref('stg_gtfs_guidelines__feed_guideline_index') }}
    WHERE check = {{ trip_id_alignment() }}
),

-- gtfs_rt_fact_files_wide_hourly has one row per day per ID+URL+feed type
gtfs_rt_fact_files_wide_daily AS (
SELECT * FROM {{ ref('gtfs_rt_fact_files_wide_hourly') }}
),

gtfs_rt_fact_daily_validation_errors AS (
    SELECT * FROM {{ ref('gtfs_rt_fact_daily_validation_errors') }}
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
        feed_key,
        date,
        SUM(occurrences) AS errors
    FROM gtfs_rt_fact_daily_validation_errors AS t1
    -- Description for error E003:
    ---- "All trip_ids provided in the GTFS-rt feed must exist in the GTFS data, unless the schedule_relationship is ADDED"
    WHERE error_id = "E003"
    GROUP BY feed_key, date
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
        t1.feed_key,
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
