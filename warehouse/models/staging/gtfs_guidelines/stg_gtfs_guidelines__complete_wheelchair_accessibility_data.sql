WITH feed_guideline_index AS (
    SELECT * FROM {{ ref('stg_gtfs_guidelines__feed_guideline_index') }}
    WHERE check = {{ complete_wheelchair_accessibility_data() }}
),

dim_trips AS (
    SELECT * FROM {{ ref('gtfs_schedule_dim_trips') }}
),

dim_stops AS (
    SELECT * FROM {{ ref('gtfs_schedule_dim_stops') }}
),

summarize_trips AS (
   SELECT
       calitp_itp_id,
       calitp_url_number,
       calitp_extracted_at,
       calitp_deleted_at,
       COUNTIF(wheelchair_accessible IS NOT NULL) AS ct_accessible_trips,
       COUNT(*) AS ct_trips
    FROM dim_trips
   GROUP BY 1, 2, 3, 4
),

daily_trips AS (
  SELECT
    t1.date,
    t1.calitp_itp_id,
    t1.calitp_url_number,
    t1.calitp_agency_name,
    t1.feed_key,
    t1.check,
    t1.feature,
    SUM(t2.ct_accessible_trips) AS tot_accessible_trips,
    SUM(t2.ct_trips) AS tot_trips
  FROM feed_guideline_index AS t1
  LEFT JOIN summarize_trips AS t2
       ON t1.date >= t2.calitp_extracted_at
       AND t1.date < t2.calitp_deleted_at
       AND t1.calitp_itp_id = t2.calitp_itp_id
       AND t1.calitp_url_number = t2.calitp_url_number
 GROUP BY
        t1.date,
        t1.calitp_itp_id,
        t1.calitp_url_number,
        t1.calitp_agency_name,
        t1.feed_key,
        t1.check,
        t1.feature
),

summarize_stops AS (
   SELECT
       calitp_itp_id,
       calitp_url_number,
       calitp_extracted_at,
       calitp_deleted_at,
       COUNTIF(wheelchair_boarding IS NOT NULL) AS ct_accessible_stops,
       COUNT(*) AS ct_stops
    FROM dim_stops
   GROUP BY 1, 2, 3, 4
),

daily_stops AS (
  SELECT
    t1.date,
    t1.calitp_itp_id,
    t1.calitp_url_number,
    t1.calitp_agency_name,
    t1.feed_key,
    t1.check,
    t1.feature,
    SUM(t2.ct_accessible_stops) AS tot_accessible_stops,
    SUM(t2.ct_stops) AS tot_stops
  FROM feed_guideline_index AS t1
  LEFT JOIN summarize_stops AS t2
       ON t1.date >= t2.calitp_extracted_at
       AND t1.date < t2.calitp_deleted_at
       AND t1.calitp_itp_id = t2.calitp_itp_id
       AND t1.calitp_url_number = t2.calitp_url_number
 GROUP BY
        t1.date,
        t1.calitp_itp_id,
        t1.calitp_url_number,
        t1.calitp_agency_name,
        t1.feed_key,
        t1.check,
        t1.feature
),

accessibility_check AS (
    SELECT
        t1.date,
        t1.calitp_itp_id,
        t1.calitp_url_number,
        t1.calitp_agency_name,
        t1.feed_key,
        t1.check,
        t1.feature,
        t1.tot_trips,
        t1.tot_accessible_trips,
        t2.tot_stops,
        t2.tot_accessible_stops,
        CASE
            WHEN t1.tot_accessible_trips = t1.tot_trips AND t2.tot_accessible_stops = t2.tot_stops THEN "PASS"
        ELSE "FAIL"
        END AS status,
      FROM daily_trips t1
      LEFT JOIN daily_stops t2
             ON t1.date = t2.date
            AND t1.calitp_itp_id = t2.calitp_itp_id
            AND t1.calitp_url_number = t2.calitp_url_number
            AND t1.feed_key = t2.feed_key
            AND t1.check = t2.check
            AND t1.feature = t2.feature
)

SELECT * FROM accessibility_check
