
-- stop_id
-- route_id
-- agency_id
WITH feed_guideline_index AS (
    SELECT * FROM {{ ref('int_gtfs_quality__schedule_feed_guideline_index') }}
),

dim_stops AS (
    SELECT  *,
            CONCAT(stop_lat,stop_lon) AS stop_location
      FROM {{ ref('dim_stops') }}
),

dim_routes AS (
    SELECT  *
      FROM {{ ref('dim_routes') }}
),

distinct_feed_versions AS (
    SELECT base64_url,
           key AS feed_key,
           _valid_from
      FROM {{ ref('dim_schedule_feeds') }}
),

-- Maps each feed_key to the feed_key of the previous version of that feed
feed_version_history AS (
    SELECT base64_url,
           feed_key,
           LAG (feed_key) OVER (PARTITION BY base64_url ORDER BY _valid_from ASC) AS prev_feed_key,
           LEAD (feed_key) OVER (PARTITION BY base64_url ORDER BY _valid_from ASC) AS next_feed_key,
           LEAD (EXTRACT(date FROM _valid_from)) OVER (PARTITION BY base64_url ORDER BY _valid_from ASC) AS next_feed_valid_from,
           EXTRACT(date FROM _valid_from) AS valid_from
      FROM distinct_feed_versions
),

stops_version_history AS (
    SELECT t1.stop_id,
           t1.feed_key,
           t2.base64_url,
           t2.prev_feed_key,
           t2.next_feed_key,
           t2.next_feed_valid_from,
           t2.valid_from
      FROM dim_stops AS t1
      JOIN feed_version_history AS t2
        ON t2.feed_key = t1.feed_key
    -- Since we are comparing feeds with their previous version, omit the initial version of every feed - no comparison is possible
     WHERE t2.prev_feed_key IS NOT null
),

stops_version_compare AS (
  SELECT
         -- base64_url is same between feed versions
         COALESCE(stops.base64_url,prev_stops.base64_url) AS base64_url,
         -- one feed's key is the previous feed's next key
         COALESCE(stops.feed_key,prev_stops.next_feed_key) AS feed_key,
         -- one feed's previous key is the previous feed's key
         COALESCE(stops.prev_feed_key,prev_stops.feed_key) AS prev_feed_key,
         -- we need to know the next feed's valid_from date, in cases where a trip is removed since the previous feed
         COALESCE(stops.valid_from,prev_stops.next_feed_valid_from) AS valid_from,
         stops.stop_id,
         prev_stops.stop_id AS prev_stop_id
    FROM stops_version_history AS stops
    FULL OUTER JOIN stops_version_history AS prev_stops
      ON stops.prev_feed_key = prev_stops.feed_key
     AND stops.stop_id = prev_stops.stop_id
),

stop_id_comparison AS (
  SELECT base64_url,
         feed_key,
         valid_from AS date,
         -- Total stop_id's in current and previous feeds
         COUNT(CASE WHEN stop_id IS NOT null AND prev_stop_id IS NOT null THEN 1 END) AS stops_both_feeds,
         -- Total stop_id's in current feed
         COUNT(CASE WHEN stop_id IS NOT null THEN 1 END) AS stops_current_feed,
         -- Total stop_id's in current feed
         COUNT(CASE WHEN prev_stop_id IS NOT null THEN 1 END) AS stops_prev_feed,
         -- New stop_id's added
         COUNT(CASE WHEN prev_stop_id IS null THEN 1 END) AS stop_added,
         -- Previous stop_id's removed
         COUNT(CASE WHEN stop_id IS null THEN 1 END) AS stop_removed,
         -- Measure what percent of stops in current feed have been added since previous feed
         (COUNT(CASE WHEN prev_stop_id IS null THEN 1 END) * 100.0
              / COUNT(CASE WHEN stop_id IS NOT null THEN 1 END)
         ) AS percent_stops_new
    FROM stops_version_compare
   GROUP BY 1,2,3
),

id_change_count AS (
    SELECT t1.date,
           t1.feed_key,
           MAX(t2.percent_stops_new)
               OVER (
                   PARTITION BY t2.feed_key
                   ORDER BY t2.date
                   ROWS BETWEEN 30 PRECEDING AND CURRENT ROW
                ) AS max_percent_stops_new
      FROM feed_guideline_index AS t1
      LEFT JOIN stop_id_comparison AS t2
        ON t1.feed_key = t2.feed_key
),

int_gtfs_quality__persistent_ids_schedule AS (
    SELECT date,
           feed_key,
           {{ persistent_ids_schedule() }} AS check,
           {{ best_practices_alignment_schedule() }} AS feature,
           CASE WHEN max_percent_stops_new > 50 THEN "FAIL"
                ELSE "PASS"
           END AS status
      FROM id_change_count
)

SELECT * FROM int_gtfs_quality__persistent_ids_schedule
