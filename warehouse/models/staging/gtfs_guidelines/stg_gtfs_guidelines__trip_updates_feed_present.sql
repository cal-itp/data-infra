WITH feed_guideline_index AS (
    SELECT * FROM {{ ref('stg_gtfs_guidelines__feed_guideline_index') }}
    WHERE check = {{ vehicle_positions_feed_present() }}
),

-- It's called "hourly" but if you use the "file_count_day" it's a daily table
gtfs_rt_fact_files_wide_daily AS (
SELECT * FROM {{ ref('gtfs_rt_fact_files_wide_hourly') }}
),

rt_files_by_day AS (
    SELECT
        calitp_itp_id,
        calitp_url_number,
        date_extracted AS date,
        name
    FROM gtfs_rt_fact_files_wide_daily
    WHERE name = "trip_updates"
),

feed_daily_check AS (
    SELECT
        t1.date,
        t1.calitp_itp_id,
        t1.calitp_url_number,
        t1.calitp_agency_name,
        t1.check,
        t1.feature,
        CASE
            WHEN t2.name IS NOT null THEN "PASS"
        ELSE "FAIL"
        END AS status,
    FROM feed_guideline_index AS t1
    LEFT JOIN rt_files_by_day AS t2
         ON t1.calitp_itp_id = t2.calitp_itp_id
         AND t1.calitp_url_number = t2.calitp_url_number
         AND t1.date = t2.date
)

SELECT * FROM feed_daily_check
