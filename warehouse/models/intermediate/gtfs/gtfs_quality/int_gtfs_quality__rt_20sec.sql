WITH feed_guideline_index AS (
    SELECT * FROM {{ ref('int_gtfs_quality__rt_feed_guideline_index') }}
    WHERE date > '2022-12-01'
      AND feed_type IN ("vehicle_positions", "trip_updates")
),

parse_outcomes AS (
    SELECT * FROM {{ ref('int_gtfs_rt__unioned_parse_outcomes') }}
     WHERE feed_type IN ("vehicle_positions", "trip_updates")
       AND dt > '2022-12-01'
),

parse_outcomes_lag_ts AS (
  SELECT
          dt AS date,
          base64_url,
          extract_ts,
          LAG (extract_ts) OVER (PARTITION BY base64_url ORDER BY extract_ts) AS prev_extract_ts
    FROM parse_outcomes
),

daily_max_lag AS (
SELECT
          date,
          base64_url,
          MAX(DATE_DIFF(extract_ts, prev_extract_ts, SECOND)) AS max_lag
  FROM parse_outcomes_lag_ts
 GROUP BY 1,2
),

int_gtfs_quality__rt_20sec AS (
    SELECT
        idx.date,
        idx.base64_url,
        idx.feed_type,
        CASE WHEN idx.feed_type = 'trip_updates' THEN {{ rt_20sec_tu() }}
             WHEN idx.feed_type = 'vehicle_positions' THEN {{ rt_20sec_vp() }}
        END AS check,
        {{ accurate_service_data() }} AS feature,
        max_lag,
        CASE
            WHEN max_lag > 20 THEN "FAIL"
            WHEN max_lag <= 20 THEN "PASS"
        END AS status,
    FROM feed_guideline_index AS idx
    LEFT JOIN daily_max_lag AS files
           ON idx.date = files.date
          AND idx.base64_url = files.base64_url
)

SELECT * FROM int_gtfs_quality__rt_20sec
