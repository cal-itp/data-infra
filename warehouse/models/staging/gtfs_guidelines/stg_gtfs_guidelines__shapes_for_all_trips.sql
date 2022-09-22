WITH feed_guideline_index AS (
    SELECT * FROM {{ ref('stg_gtfs_guidelines__feed_guideline_index') }}
    WHERE check = {{ shapes_for_all_trips() }}
),

dim_trips AS (
    SELECT * FROM {{ ref('gtfs_schedule_dim_trips') }}
),

dim_shapes AS (
    SELECT * FROM {{ ref('gtfs_schedule_dim_shapes') }}
),

trip_shape_ids AS (
   SELECT
       calitp_itp_id,
       calitp_url_number,
       calitp_extracted_at,
       calitp_deleted_at,
       shape_id,
       COUNT(*) AS ct_trips
    FROM dim_trips
   GROUP BY 1, 2, 3, 4, 5
),

trips_shapes_joined AS (
   SELECT
       t1.calitp_itp_id,
       t1.calitp_url_number,
       t1.calitp_extracted_at,
       t1.calitp_deleted_at,
       t1.shape_id AS trips_shape_id,
       t2.shape_id AS shapes_shape_id
    FROM trip_shape_ids AS t1
    LEFT JOIN dim_shapes AS t2
           ON t1.calitp_itp_id = t2.calitp_itp_id
           AND t1.calitp_url_number = t2.calitp_url_number
           AND t1.shape_id = t2.shape_id
           AND t1.calitp_extracted_at = t2.calitp_extracted_at
           AND t1.calitp_deleted_at = t2.calitp_deleted_at
),

missing_shape_count AS (
    SELECT
       calitp_itp_id,
       calitp_url_number,
       calitp_extracted_at,
       calitp_deleted_at,
       COUNTIF(shapes_shape_id IS null) AS missing_shapes
   FROM trips_shapes_joined
  GROUP BY 1,2,3,4
),

daily_missing_shapes AS (
  SELECT
    t1.date,
    t1.calitp_itp_id,
    t1.calitp_url_number,
    t1.calitp_agency_name,
    t1.feed_key,
    t1.check,
    t1.feature,
    SUM(t2.missing_shapes) AS tot_missing_shapes
  FROM feed_guideline_index AS t1
  LEFT JOIN missing_shape_count AS t2
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

missing_shapes_check AS (
  SELECT
    date,
    calitp_itp_id,
    calitp_url_number,
    calitp_agency_name,
    feed_key,
    check,
    feature,
    CASE
        WHEN tot_missing_shapes = 0 THEN "PASS"
        WHEN tot_missing_shapes > 0 THEN "FAIL"
    END AS status,
  FROM daily_missing_shapes
)

SELECT * FROM missing_shapes_check
