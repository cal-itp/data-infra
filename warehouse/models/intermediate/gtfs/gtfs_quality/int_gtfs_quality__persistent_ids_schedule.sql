
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

dim_agency AS (
    SELECT  *
      FROM {{ ref('dim_agency') }}
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
           EXTRACT(date FROM _valid_from) AS valid_from,
           ROW_NUMBER () OVER (PARTITION BY base64_url ORDER BY _valid_from ASC) feed_version_number
      FROM distinct_feed_versions
),

stop_ids_version_history AS (
    SELECT t1.stop_id,
           t1.feed_key,
           t2.base64_url,
           t2.prev_feed_key,
           t2.next_feed_key,
           t2.next_feed_valid_from,
           t2.valid_from,
           t2.feed_version_number
      FROM dim_stops AS t1
      JOIN feed_version_history AS t2
        ON t2.feed_key = t1.feed_key
),

stop_ids_version_compare AS (
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
    FROM stop_ids_version_history AS stops
    FULL OUTER JOIN stop_ids_version_history AS prev_stops
      ON stops.prev_feed_key = prev_stops.feed_key
     AND stops.stop_id = prev_stops.stop_id
   -- The first feed version doesn't have a previous to compare to
   WHERE stops.feed_version_number > 1
),

stop_id_comparison AS (
  SELECT base64_url,
         feed_key,
         -- Total stop_id's in current and previous feeds
         COUNT(CASE WHEN stop_id IS NOT null AND prev_stop_id IS NOT null THEN 1 END) AS stop_ids_both_feeds,
         -- Total stop_id's in current feed
         COUNT(CASE WHEN stop_id IS NOT null THEN 1 END) AS stop_ids_current_feed,
         -- Total stop_id's in current feed
         COUNT(CASE WHEN prev_stop_id IS NOT null THEN 1 END) AS stop_ids_prev_feed,
         -- New stop_id's added
         COUNT(CASE WHEN prev_stop_id IS null THEN 1 END) AS stop_id_added,
         -- Previous stop_id's removed
         COUNT(CASE WHEN stop_id IS null THEN 1 END) AS stop_id_removed
    FROM stop_ids_version_compare
   GROUP BY 1,2
  HAVING stop_ids_current_feed > 0
),

route_ids_version_history AS (
    SELECT t1.route_id,
           t1.feed_key,
           t2.base64_url,
           t2.prev_feed_key,
           t2.next_feed_key,
           t2.next_feed_valid_from,
           t2.valid_from,
           t2.feed_version_number
      FROM dim_routes AS t1
      JOIN feed_version_history AS t2
        ON t2.feed_key = t1.feed_key
),

route_ids_version_compare AS (
  SELECT
         -- base64_url is same between feed versions
         COALESCE(routes.base64_url,prev_routes.base64_url) AS base64_url,
         -- one feed's key is the previous feed's next key
         COALESCE(routes.feed_key,prev_routes.next_feed_key) AS feed_key,
         -- one feed's previous key is the previous feed's key
         COALESCE(routes.prev_feed_key,prev_routes.feed_key) AS prev_feed_key,
         -- we need to know the next feed's valid_from date, in cases where a trip is removed since the previous feed
         COALESCE(routes.valid_from,prev_routes.next_feed_valid_from) AS valid_from,
         routes.route_id,
         prev_routes.route_id AS prev_route_id
    FROM route_ids_version_history AS routes
    FULL OUTER JOIN route_ids_version_history AS prev_routes
      ON routes.prev_feed_key = prev_routes.feed_key
     AND routes.route_id = prev_routes.route_id
   -- The first feed version doesn't have a previous to compare to
   WHERE routes.feed_version_number > 1
),

route_id_comparison AS (
  SELECT base64_url,
         feed_key,
         -- Total route_id's in current and previous feeds
         COUNT(CASE WHEN route_id IS NOT null AND prev_route_id IS NOT null THEN 1 END) AS route_ids_both_feeds,
         -- Total route_id's in current feed
         COUNT(CASE WHEN route_id IS NOT null THEN 1 END) AS route_ids_current_feed,
         -- Total route_id's in current feed
         COUNT(CASE WHEN prev_route_id IS NOT null THEN 1 END) AS route_ids_prev_feed,
         -- New route_id's added
         COUNT(CASE WHEN prev_route_id IS null THEN 1 END) AS route_id_added,
         -- Previous route_id's removed
         COUNT(CASE WHEN route_id IS null THEN 1 END) AS route_id_removed,
    FROM route_ids_version_compare
   GROUP BY 1,2
  HAVING route_ids_current_feed > 0
),

agency_ids_version_history AS (
    SELECT t1.agency_id,
           t1.feed_key,
           t2.base64_url,
           t2.prev_feed_key,
           t2.next_feed_key,
           t2.next_feed_valid_from,
           t2.valid_from,
           t2.feed_version_number
      FROM dim_agency AS t1
      JOIN feed_version_history AS t2
        ON t2.feed_key = t1.feed_key
),

agency_ids_version_compare AS (
  SELECT
         -- base64_url is same between feed versions
         COALESCE(agencies.base64_url,prev_agencies.base64_url) AS base64_url,
         -- one feed's key is the previous feed's next key
         COALESCE(agencies.feed_key,prev_agencies.next_feed_key) AS feed_key,
         -- one feed's previous key is the previous feed's key
         COALESCE(agencies.prev_feed_key,prev_agencies.feed_key) AS prev_feed_key,
         -- we need to know the next feed's valid_from date, in cases where a trip is removed since the previous feed
         COALESCE(agencies.valid_from,prev_agencies.next_feed_valid_from) AS valid_from,
         agencies.agency_id,
         prev_agencies.agency_id AS prev_agency_id
    FROM agency_ids_version_history AS agencies
    FULL OUTER JOIN agency_ids_version_history AS prev_agencies
      ON agencies.prev_feed_key = prev_agencies.feed_key
     AND agencies.agency_id = prev_agencies.agency_id
   -- The first feed version doesn't have a previous to compare to
   WHERE agencies.feed_version_number > 1
),

agency_id_comparison AS (
  SELECT base64_url,
         feed_key,
         -- Total agency_id's in current and previous feeds
         COUNT(CASE WHEN agency_id IS NOT null AND prev_agency_id IS NOT null THEN 1 END) AS agency_ids_both_feeds,
         -- Total agency_id's in current feed
         COUNT(CASE WHEN agency_id IS NOT null THEN 1 END) AS agency_ids_current_feed,
         -- Total agency_id's in current feed
         COUNT(CASE WHEN prev_agency_id IS NOT null THEN 1 END) AS agency_ids_prev_feed,
         -- New agency_id's added
         COUNT(CASE WHEN prev_agency_id IS null THEN 1 END) AS agency_id_added,
         -- Previous agency_id's removed
         COUNT(CASE WHEN agency_id IS null THEN 1 END) AS agency_id_removed
    FROM agency_ids_version_compare
   GROUP BY 1,2
  HAVING agency_ids_current_feed > 0
),

id_change_count AS (
    SELECT t1.date,
           t1.feed_key,
           MAX(t2.stop_id_added * 100 / t2.stop_ids_current_feed )
               OVER (
                   PARTITION BY t1.feed_key
                   ORDER BY t1.date
                   ROWS BETWEEN 30 PRECEDING AND CURRENT ROW
                ) AS max_percent_stop_ids_new,
           MAX(t3.route_id_added * 100 / t3.route_ids_current_feed )
               OVER (
                   PARTITION BY t1.feed_key
                   ORDER BY t1.date
                   ROWS BETWEEN 30 PRECEDING AND CURRENT ROW
                ) AS max_percent_route_ids_new,
           MAX(t4.agency_id_added * 100 / t4.agency_ids_current_feed )
               OVER (
                   PARTITION BY t1.feed_key
                   ORDER BY t1.date
                   ROWS BETWEEN 30 PRECEDING AND CURRENT ROW
                ) AS max_percent_agency_ids_new
      FROM feed_guideline_index AS t1
      LEFT JOIN stop_id_comparison AS t2
        ON t2.feed_key = t1.feed_key
      LEFT JOIN route_id_comparison AS t3
        ON t3.feed_key = t1.feed_key
      LEFT JOIN agency_id_comparison AS t4
        ON t4.feed_key = t1.feed_key
),

int_gtfs_quality__persistent_ids_schedule AS (
    SELECT date,
           feed_key,
           {{ persistent_ids_schedule() }} AS check,
           {{ best_practices_alignment_schedule() }} AS feature,
           CASE WHEN max_percent_stop_ids_new > 50
                     OR max_percent_route_ids_new > 50
                     OR max_percent_agency_ids_new > 50
                THEN "FAIL"
                ELSE "PASS"
           END AS status
      FROM id_change_count
)

SELECT * FROM int_gtfs_quality__persistent_ids_schedule
