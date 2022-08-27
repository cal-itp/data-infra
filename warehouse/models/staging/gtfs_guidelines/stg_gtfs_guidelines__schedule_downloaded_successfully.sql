WITH feed_guideline_index AS (
    SELECT * FROM {{ ref('stg_gtfs_guidelines__feed_guideline_index') }}
    WHERE check = {{ static_feed_downloaded_successfully() }}
),

gtfs_schedule_fact_daily_feeds AS (
    SELECT * FROM {{ ref('gtfs_schedule_fact_daily_feeds') }}
),

static_feed_downloaded_successfully_check AS (
    SELECT
        feed_key,
        date,
        CASE
            WHEN extraction_status = "success" THEN "PASS"
            WHEN extraction_status = "error" THEN "FAIL"
        ELSE null
        END AS status,
        {{ static_feed_downloaded_successfully() }} AS check
    FROM gtfs_schedule_fact_daily_feeds
),

static_feed_downloaded_successfully_check_idx AS (
    SELECT
        t1.date,
        t1.calitp_itp_id,
        t1.calitp_url_number,
        t1.calitp_agency_name,
        t1.check,
        t2.status,
        t1.feature,
    FROM feed_guideline_index AS t1
    LEFT JOIN static_feed_downloaded_successfully_check AS t2
        USING (feed_key, date, check)
)

SELECT * FROM static_feed_downloaded_successfully_check_idx
