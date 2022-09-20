WITH feed_guideline_index AS (
    SELECT * FROM {{ ref('stg_gtfs_guidelines__feed_guideline_index') }}
    WHERE check = {{ schedule_feed_on_transitland() }}
),

fact_daily_transitland_url_check AS (
SELECT * FROM {{ ref('stg_gtfs_guidelines__fact_daily_transitland_url_check') }}
),

schedule_daily_check AS (
    SELECT
        calitp_itp_id,
        calitp_url_number,
        dt AS date,
        transitland_status
    FROM fact_daily_transitland_url_check
    WHERE url_type = "gtfs_schedule_url"
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
            WHEN t2.transitland_status = 'present' THEN "PASS"
        ELSE "FAIL"
        END AS status,
    FROM feed_guideline_index AS t1
    LEFT JOIN schedule_daily_check AS t2
         ON t1.calitp_itp_id = t2.calitp_itp_id
         AND t1.calitp_url_number = t2.calitp_url_number
         AND t1.date = t2.date
)

SELECT * FROM feed_daily_check
