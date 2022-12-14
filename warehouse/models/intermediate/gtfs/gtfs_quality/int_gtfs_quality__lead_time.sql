WITH feed_guideline_index AS (
    SELECT * FROM {{ ref('int_gtfs_quality__schedule_feed_guideline_index') }}
),

all_scheduled_service AS (
    SELECT *
      FROM {{ ref('int_gtfs_schedule__all_scheduled_service') }}
),

dim_stop_times AS (
    SELECT  *,
            CONCAT(arrival_time, departure_time) AS time_pair,
      FROM {{ ref('dim_stop_times') }}
),

dim_stops AS (
    SELECT  *,
            CONCAT(stop_lat,stop_lon) AS stop_location
      FROM {{ ref('dim_stops') }}
),

dim_trips AS (
    SELECT  *
      FROM {{ ref('dim_trips') }}
),

distinct_feed_versions AS (
    SELECT base64_url,
           key AS feed_key,
           _valid_from
      FROM {{ ref('dim_schedule_feeds') }}
),

-- Aggregate information about each trip, including stops & stop times
trips_expanded AS (
    SELECT t1.feed_key,
           t1.trip_id,
           t1.service_id,
           -- Creates a hash for a single field summarizing all stop_times this trip
           MD5(
                STRING_AGG(
                    time_pair ORDER BY t2.stop_sequence ASC
                )
            ) AS trip_stop_times_hash,
           -- Creates a hash for a single field summarizing all stop locations for this trip
           MD5(
                STRING_AGG(
                    stop_location ORDER BY t2.stop_sequence ASC
                )
            ) AS trip_stop_locations_hash
      FROM dim_trips t1
      LEFT JOIN dim_stop_times t2
        ON t2.trip_id = t1.trip_id
       AND t2.feed_key = t1.feed_key
      LEFT JOIN dim_stops t3
        ON t3.stop_id = t2.stop_id
       AND t3.feed_key = t2.feed_key
     GROUP BY 1,2,3
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

scheduled_trips_version_history AS (
    SELECT t1.service_date,
           t1.feed_key,
           t2.trip_id,
           t2.trip_stop_times_hash,
           t2.trip_stop_locations_hash,
           t3.base64_url,
           t3.prev_feed_key,
           t3.next_feed_key,
           t3.next_feed_valid_from,
           t3.valid_from
      FROM all_scheduled_service t1
      LEFT JOIN trips_expanded t2
        ON t2.service_id = t1.service_id
       AND t2.feed_key = t1.feed_key
      JOIN feed_version_history t3
        ON t3.feed_key = t1.feed_key
    -- Since we are comparing feeds with their previous version, omit the initial version of every feed - no comparison is possible
     WHERE t3.prev_feed_key IS NOT null
),

-- The self-outer-join, with all of the coalescing, allows us to see:
------ 1 trips that were REMOVED since the previous version
------ 2 trips that were ADDED since the previous version
------ 3 trips that were CHANGED since the previous version
trips_version_compare AS (
  SELECT
         -- base64_url is same between feed versions
         COALESCE(trips.base64_url,prev_trips.base64_url) AS base64_url,
         -- one feed's key is the previous feed's next key
         COALESCE(trips.feed_key,prev_trips.next_feed_key) AS feed_key,
         -- one feed's previous key is the previous feed's key
         COALESCE(trips.prev_feed_key,prev_trips.feed_key) AS prev_feed_key,
         -- we need to know the next feed's valid_from date, in cases where a trip is removed since the previous feed
         COALESCE(trips.valid_from,prev_trips.next_feed_valid_from) AS valid_from,
         DATE_DIFF(
                     COALESCE(trips.service_date, prev_trips.service_date),
                     COALESCE(trips.valid_from,prev_trips.next_feed_valid_from),
                     DAY
         ) AS days_until_service_date,
         trips.trip_id,
         trips.trip_stop_times_hash,
         trips.trip_stop_locations_hash,
         prev_trips.trip_id AS prev_trip_id,
         prev_trips.trip_stop_times_hash AS prev_trip_stop_times_hash,
         prev_trips.trip_stop_locations_hash AS prev_trip_stop_locations_hash
    FROM scheduled_trips_version_history AS trips
    FULL OUTER JOIN scheduled_trips_version_history AS prev_trips
      ON trips.prev_feed_key = prev_trips.feed_key
     AND trips.trip_id = prev_trips.trip_id
     AND trips.service_date = prev_trips.service_date
),

-- We count each infraction seprately, mostly for QA purposes
daily_improper_trips_updates AS (
  SELECT base64_url,
         feed_key,
         valid_from AS date,
          -- A new trip is being added
         COUNT(CASE WHEN prev_trip_id IS null THEN 1 END) AS trip_added,
          -- An existing trip is being removed
         COUNT(CASE WHEN trip_id IS null THEN 1 END) AS trip_removed,
          -- A trip's stop times are being changed
         COUNT(CASE WHEN trip_stop_times_hash != prev_trip_stop_times_hash THEN 1 END) AS stop_times_changed,
          -- A trip's stop location is being changed
          ---- Note that this will catch micro-adjustments as well as large changes.
          ---- ...consider calculating distance and setting a minimum allowable change
         COUNT(CASE WHEN trip_stop_locations_hash != prev_trip_stop_locations_hash THEN 1 END) AS stop_location_changed,
    FROM trips_version_compare
   WHERE
         -- Service date is between 0 and 7 days from now
         days_until_service_date > 0 AND days_until_service_date <= 7
   GROUP BY 1,2,3
),

feed_update_count AS (
    SELECT t1.date,
           t1.feed_key,
           SUM(t2.trip_added + t2.trip_removed + t2.stop_times_changed + t2.stop_location_changed)
               OVER (
                   PARTITION BY t2.feed_key
                   ORDER BY t2.date
                   ROWS BETWEEN 30 PRECEDING AND CURRENT ROW
                ) AS trips_updates_last_30_days
      FROM feed_guideline_index AS t1
      LEFT JOIN daily_improper_trips_updates AS t2
        ON t1.feed_key = t2.feed_key
),

int_gtfs_quality__lead_time AS (
    SELECT date,
           feed_key,
           {{ lead_time() }} AS check,
           {{ up_to_dateness() }} AS feature,
           CASE WHEN trips_updates_last_30_days > 0 THEN "FAIL"
                ELSE "PASS"
           END AS status
      FROM feed_update_count
)

SELECT * FROM int_gtfs_quality__lead_time
