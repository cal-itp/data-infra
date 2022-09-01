WITH feed_guideline_index AS (
    SELECT * FROM {{ ref('stg_gtfs_guidelines__feed_guideline_index') }}
    WHERE check = {{ complete_wheelchair_boarding_data() }}
),

gtfs_schedule_fact_daily_trips AS (
    SELECT * FROM {{ ref('gtfs_schedule_fact_daily_trips') }}
),

gtfs_schedule_fact_daily_feed_stops AS (
    SELECT * FROM {{ ref('gtfs_schedule_fact_daily_feed_stops') }}
),

gtfs_schedule_fact_daily_feeds AS (
    SELECT * FROM {{ ref('gtfs_schedule_fact_daily_feeds') }}
),

gtfs_schedule_dim_trips AS (
    SELECT * FROM {{ ref('gtfs_schedule_dim_trips') }}
),

gtfs_schedule_dim_stops AS (
    SELECT * FROM {{ ref('gtfs_schedule_dim_stops') }}
),

trips AS (
    SELECT
        t3.calitp_itp_id,
        COUNT(CASE
                WHEN t2.wheelchair_accessible IS NOT NULL THEN 1
              END) AS accessibility_trips,
        COUNT(*) AS trips
    FROM gtfs_schedule_fact_daily_trips AS t1
    LEFT JOIN gtfs_schedule_dim_trips AS t2
      ON t1.trip_key = t2.trip_key
    LEFT JOIN gtfs_schedule_fact_daily_feeds AS t3
      ON t1.feed_key = t3.feed_key
    WHERE calitp_extracted_at <= CURRENT_DATE()
      AND calitp_deleted_at > CURRENT_DATE()
    GROUP BY calitp_itp_id
),

stops AS (
    SELECT
        t3.calitp_itp_id,
        COUNT(CASE
                WHEN t2.wheelchair_boarding IS NOT NULL THEN 1
              END) AS accessibility_stops,
        COUNT(*) AS stops
    FROM gtfs_schedule_fact_daily_feed_stops AS t1
    LEFT JOIN gtfs_schedule_dim_stops AS t2
      ON t1.stop_key = t2.stop_key
    LEFT JOIN gtfs_schedule_fact_daily_feeds AS t3
      ON t1.feed_key = t3.feed_key
    WHERE calitp_extracted_at <= CURRENT_DATE()
      AND calitp_deleted_at > CURRENT_DATE()
   GROUP BY calitp_itp_id
),

wheelchair_check AS (
    SELECT
        t1.calitp_itp_id,
        CURRENT_DATE() AS date,
        {{ complete_wheelchair_accessibility_data() }} AS check,
        CASE
            WHEN accessibility_trips = trips AND accessibility_stops = stops THEN "PASS"
        ELSE "FAIL"
        END AS status
    FROM trips AS t1
    LEFT JOIN stops AS t2
        USING calitp_itp_id
),

wheelchair_check_joined AS (
    SELECT
        t1.date,
        t1.calitp_itp_id,
        t1.calitp_url_number,
        t1.calitp_agency_name,
        t1.check,
        t1.feature,
        t2.status
    FROM feed_guideline_index AS t1
    LEFT JOIN wheelchair_check AS t2
        USING (calitp_itp_id, date, check)
)

SELECT * FROM wheelchair_check_joined
