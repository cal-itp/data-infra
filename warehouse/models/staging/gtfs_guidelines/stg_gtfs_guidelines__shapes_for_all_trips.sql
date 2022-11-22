WITH feed_guideline_index AS (
    SELECT * FROM {{ ref('stg_gtfs_guidelines__feed_guideline_index') }}
    WHERE check = {{ shapes_for_all_trips() }}
),

dim_trips AS (
    SELECT * FROM {{ ref('gtfs_schedule_dim_trips') }}
),

summarize_trips AS (
   SELECT
       calitp_itp_id,
       calitp_url_number,
       calitp_extracted_at,
       calitp_deleted_at,
       COUNTIF(shape_id IS NOT NULL) AS ct_shape_trips,
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
    SUM(t2.ct_shape_trips) AS tot_shape_trips,
    SUM(t2.ct_trips) AS tot_trips
  FROM feed_guideline_index AS t1
  LEFT JOIN summarize_trips AS t2
       ON t1.date >= t2.calitp_extracted_at
       AND t1.date < t2.calitp_deleted_at
       AND t1.calitp_itp_id = t2.calitp_itp_id
       AND t1.calitp_url_number = t2.calitp_url_number
 GROUP BY 1, 2, 3, 4, 5, 6, 7
),

trip_shape_check AS (
    SELECT
        date,
        calitp_itp_id,
        calitp_url_number,
        calitp_agency_name,
        feed_key,
        check,
        feature,
        tot_shape_trips,
        tot_trips,
        CASE
            WHEN tot_shape_trips = tot_trips THEN "PASS"
        ELSE "FAIL"
        END AS status,
      FROM daily_trips
)

SELECT * FROM trip_shape_check
