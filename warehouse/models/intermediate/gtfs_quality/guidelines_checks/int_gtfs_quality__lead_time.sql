WITH guideline_index AS (
    SELECT
        *
    FROM {{ ref('int_gtfs_quality__guideline_checks_index') }}
    WHERE check = {{ lead_time() }}
),

scheduled_service_within_update_window AS (
    SELECT *
    FROM {{ ref('int_gtfs_schedule__all_scheduled_service') }}
    WHERE DATE_DIFF(service_date, EXTRACT(DATE FROM _feed_valid_from), DAY) BETWEEN 0 AND 7
),

trip_summaries AS (
    SELECT *
    FROM {{ ref('int_gtfs_quality__scheduled_trip_version_summary') }}
),

feed_version_history AS (
    SELECT *
    FROM {{ ref('int_gtfs_quality__feed_version_history') }}
),

url_date_spine AS (
    SELECT DISTINCT
        date,
        base64_url
    FROM guideline_index
    WHERE has_schedule_url
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
      FROM scheduled_service_within_update_window t1
      LEFT JOIN trip_summaries t2
        ON t2.service_id = t1.service_id
       AND t2.feed_key = t1.feed_key
      INNER JOIN feed_version_history t3
        ON t3.feed_key = t1.feed_key
    -- Since we are comparing feeds with their previous version, omit the initial version of every feed - no comparison is possible
     WHERE t3.prev_feed_key IS NOT NULL
),

-- The self-outer-join, with all of the coalescing, allows us to see:
------ 1 trips that were REMOVED since the previous version
------ 2 trips that were ADDED since the previous version
------ 3 trips that were CHANGED since the previous version
trips_version_compare AS (
  SELECT
         -- base64_url is same between feed versions
         COALESCE(trips.base64_url, prev_trips.base64_url) AS base64_url,
         -- one feed's key is the previous feed's next key
         COALESCE(trips.feed_key, prev_trips.next_feed_key) AS feed_key,
         -- one feed's previous key is the previous feed's key
         COALESCE(trips.prev_feed_key, prev_trips.feed_key) AS prev_feed_key,
         -- we need to know the next feed's valid_from date, in cases where a trip is removed since the previous feed
         COALESCE(trips.valid_from, prev_trips.next_feed_valid_from) AS valid_from,
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

-- We count each "infraction" type seperately, mostly for QA purposes
----  Note that this query will count each "infraction" once per day it's in effect
improper_trips_updates AS (
  SELECT base64_url,
         feed_key,
          -- A new trip is being added
         COUNT(CASE WHEN prev_trip_id IS NULL THEN 1 END) AS trip_added,
          -- An existing trip is being removed
         COUNT(CASE WHEN trip_id IS NULL THEN 1 END) AS trip_removed,
          -- A trip's stop times are being changed
         COUNT(CASE WHEN trip_stop_times_hash != prev_trip_stop_times_hash THEN 1 END) AS stop_times_changed,
          -- A trip's stop location is being changed
          ---- Note that this will catch micro-adjustments as well as large changes.
          ---- ...consider calculating distance and setting a minimum allowable change
         COUNT(CASE WHEN trip_stop_locations_hash != prev_trip_stop_locations_hash THEN 1 END) AS stop_location_changed,
    FROM trips_version_compare
   -- SQLFluff doesn't like numeric aliasing here alongside explicit naming in window functions
   GROUP BY 1, 2 -- noqa: L054
),

feed_update_count AS (
    SELECT
        hist.base64_url,
        hist.feed_key,
        hist.valid_from,
        hist.feed_version_number,
        SUM(trip_added + trip_removed + stop_times_changed + stop_location_changed) AS invalid_changes,
        DATE_ADD(hist.valid_from, INTERVAL 30 DAY) AS int_30_days
    FROM feed_version_history AS hist
    LEFT JOIN improper_trips_updates AS trips
      ON hist.feed_key = trips.feed_key
    -- SQLFluff doesn't like numeric aliasing here alongside explicit naming in window functions
    GROUP BY 1, 2, 3, 4 -- noqa: L054
),

-- check for ALL feed changes within 30 days
url_feed_hist AS (
    SELECT
        url_date_spine.date,
        url_date_spine.base64_url,
        SUM(CASE WHEN feed_version_number > 1 THEN invalid_changes ELSE 0 END) AS url_invalid_changes,
    FROM url_date_spine
    LEFT JOIN feed_update_count
        ON url_date_spine.base64_url = feed_update_count.base64_url
        AND url_date_spine.date BETWEEN feed_update_count.valid_from AND feed_update_count.int_30_days
    GROUP BY 1, 2
),

check_start AS (
    SELECT MIN(valid_from) AS first_check_date
    FROM feed_version_history
    WHERE prev_feed_key IS NOT NULL
),

int_gtfs_quality__lead_time AS (
    SELECT
        idx.* EXCEPT(status),
        first_check_date,
        url_invalid_changes,
        invalid_changes,
        int_30_days,
        feed_version_number,
        CASE
            WHEN has_schedule_feed
                THEN
                    CASE
                        WHEN idx.date < first_check_date THEN {{ guidelines_na_too_early_status() }}
                        WHEN (url_invalid_changes IS NULL AND idx.date < int_30_days) OR (feed_version_number = 1 AND idx.date < int_30_days) THEN {{ guidelines_na_check_status() }}
                        WHEN url_invalid_changes = 0 OR idx.date >= int_30_days THEN {{ guidelines_pass_status() }}
                        WHEN url_invalid_changes > 0 THEN {{ guidelines_fail_status() }}
                    END
            ELSE idx.status
        END AS status
    FROM guideline_index idx
    CROSS JOIN check_start
    LEFT JOIN feed_update_count
        ON idx.schedule_feed_key = feed_update_count.feed_key
    LEFT JOIN url_feed_hist
        ON idx.base64_url = url_feed_hist.base64_url
        AND idx.date  = url_feed_hist.date
)

SELECT * FROM int_gtfs_quality__lead_time
