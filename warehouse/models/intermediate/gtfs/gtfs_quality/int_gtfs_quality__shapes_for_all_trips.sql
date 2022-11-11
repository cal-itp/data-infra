WITH feed_guideline_index AS (
    SELECT * FROM {{ ref('int_gtfs_quality__schedule_feed_guideline_index') }}
),

dim_trips AS (
    SELECT * FROM {{ ref('dim_trips') }}
),

summarize_trips AS (
   SELECT
       feed_key,
       EXTRACT(date FROM _valid_from) AS valid_from,
       EXTRACT(date FROM _valid_to) AS valid_to,
       COUNTIF(shape_id IS NOT NULL) AS ct_shape_trips,
       COUNT(*) AS ct_trips
    FROM dim_trips
   GROUP BY 1, 2, 3
),

daily_trips AS (
  SELECT
    t1.date,
    t1.feed_key,
    SUM(t2.ct_shape_trips) AS tot_shape_trips,
    SUM(t2.ct_trips) AS tot_trips
  FROM feed_guideline_index AS t1
  LEFT JOIN summarize_trips AS t2
       ON t1.date >= t2.valid_from
       AND t1.date <= t2.valid_to
       AND t1.feed_key = t2.feed_key
 GROUP BY 1, 2
),

int_gtfs_quality__shapes_for_all_trips AS (
    SELECT
        date,
        feed_key,
        {{ shapes_for_all_trips() }} AS check,
        {{ accurate_service_data() }} AS feature,
        tot_shape_trips,
        tot_trips,
        CASE
            WHEN tot_shape_trips = tot_trips THEN "PASS"
        ELSE "FAIL"
        END AS status,
      FROM daily_trips
)

SELECT * FROM int_gtfs_quality__shapes_for_all_trips
