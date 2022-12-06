WITH feed_guideline_index AS (
    SELECT * FROM {{ ref('int_gtfs_quality__schedule_feed_guideline_index') }}
),

dim_calendar AS (
    SELECT  *,
            -- Single field to represent the calendar for easy comparison
            CONCAT(CAST(monday AS string), CAST(tuesday AS string), CAST(wednesday AS string), CAST(thursday AS string),
                CAST(friday AS string), CAST(saturday AS string), CAST(sunday AS string)) AS day_combo
      FROM {{ ref('dim_calendar') }}
),

dim_calendar_dates AS (
    SELECT  *,
            -- Concatting service_id and date creates a unique ID to join on
            CONCAT(service_id, date) AS service_id_date
      FROM {{ ref('dim_calendar_dates') }}
),

dim_stop_times AS (
    SELECT  *
      FROM {{ ref('dim_stop_times') }}
),

dim_stops AS (
    SELECT  *,
      FROM {{ ref('dim_stops') }}
),

dim_trips AS (
    SELECT  *
    -- Add in trips from here, including stop times
      FROM {{ ref('dim_trips') }}
),

stop_times_expanded AS (
    SELECT t1.feed_key,
           t1.trip_id,
           t1.stop_sequence,
           CONCAT(t1.arrival_time,t1.departure_time,t2.stop_lat,t2.stop_lon) AS stop_info_combined
      FROM dim_stop_times t1
      LEFT JOIN dim_stops t2
        ON t2.stop_id = t1.stop_id
       AND t2.feed_key = t1.feed_key
),

stop_times_agg AS (
    SELECT feed_key,
           trip_id,
           -- A single field summarizing all stops & times for this trip, for easy comparison
           STRING_AGG(stop_info_combined ORDER BY stop_sequence ASC) AS stop_info_agg
      FROM stop_times_expanded
     GROUP BY 1,2
),

-- Aggregate information about each trip, including stops, stop times, and calendar attributes
trips_expanded AS (
    SELECT t1.feed_key,
           t1.trip_id,
           -- Combine stop & schedule summary fields for one summary field to rule them all
           CONCAT(t2.stop_info_agg,t3.day_combo) AS trip_info_combined,
           t3.start_date,
           t3.end_date
      FROM dim_trips t1
      LEFT JOIN stop_times_agg t2
        ON t2.trip_id = t1.trip_id
       AND t2.feed_key = t1.feed_key
      LEFT JOIN dim_calendar t3
        ON t3.service_id = t1.service_id
       AND t3.feed_key = t1.feed_key
),

distinct_feed_versions AS (
    SELECT base64_url,
           key AS feed_key,
           _valid_from
      FROM {{ ref('dim_schedule_feeds') }}
     WHERE key IS NOT null
),

-- Maps each feed_key to the feed_key of the previous version of that feed
feed_version_history AS (
    SELECT base64_url,
           feed_key,
           LAG (feed_key) OVER (PARTITION BY base64_url ORDER BY _valid_from ASC) AS previous_feed_key,
           EXTRACT(date FROM _valid_from) AS valid_from
      FROM distinct_feed_versions
),

trips_version_compare AS (
  SELECT t1.base64_url,
         t1.feed_key,
         t1.valid_from,
         trips.trip_info_combined AS trip_info_combined,
         prev_trips.trip_info_combined AS prev_trip_info_combined,
         DATE_DIFF(valid_from, trips.start_date, DAY) AS days_since_start_date,
         DATE_DIFF(trips.end_date, valid_from, DAY) AS days_until_end_date
    FROM feed_version_history AS t1
    -- Inner join, so that there will be one row for every trip for every feed
    JOIN trips_expanded AS trips
      ON t1.feed_key = trips.feed_key
    -- Left join, so that prev_trips fields will be null in cases where a new trip has been added
    LEFT JOIN trips_expanded AS prev_trips
      ON t1.previous_feed_key = prev_trips.feed_key
     AND trips.trip_id = prev_trips.trip_id
),

daily_improper_trip_updates AS (
  SELECT feed_key,
         valid_from AS date,
         COUNT(*) AS updates
    FROM trips_version_compare
   WHERE (
            -- Something has changed about the trip since the previous version
            trip_info_combined != prev_trip_info_combined
         OR
            -- This trip_id wasn't in the previous version
            prev_trip_info_combined IS null
         )
         -- Start date is no later than 7 days from now (can be in the past)
         AND days_since_start_date > -7
         -- End date is in the future
         AND days_until_end_date > 0
   GROUP BY 1,2
),

calendar_dates_joined AS (
  SELECT t1.base64_url,
         t1.feed_key,
         t1.valid_from,
         cal_dates.exception_type,
         prev_cal_dates.exception_type AS prev_exception_type,
         DATE_DIFF(cal_dates.date, valid_from, DAY) AS days_until_date
    FROM feed_version_history AS t1
    JOIN dim_calendar_dates AS cal_dates
      ON t1.feed_key = cal_dates.feed_key
    LEFT JOIN dim_calendar_dates AS prev_cal_dates
      ON t1.previous_feed_key = prev_cal_dates.feed_key
     AND cal_dates.service_id_date = prev_cal_dates.service_id_date
),

daily_improper_calendar_dates_updates AS (
  SELECT feed_key,
         valid_from AS date,
         COUNT(*) AS updates
    FROM calendar_dates_joined
   WHERE (
            -- A new calendar_date is being added
            prev_exception_type IS null
            OR
            -- An existing calendar_date is changing its exception_type
            exception_type != prev_exception_type
         )
         AND
         (
            -- Date is in the past
            days_until_date < 0
            OR
            -- Date is more than 7 days from now
            days_until_date > 7
         )
   GROUP BY 1,2
),

feed_update_count AS (
    SELECT t1.date,
           t1.feed_key,
           SUM(t2.updates)
               OVER (
                   PARTITION BY t2.feed_key
                   ORDER BY t2.date
                   ROWS BETWEEN 30 PRECEDING AND CURRENT ROW
                ) AS trip_updates_last_30_days,
           SUM(t3.updates)
               OVER (
                   PARTITION BY t3.feed_key
                   ORDER BY t3.date
                   ROWS BETWEEN 30 PRECEDING AND CURRENT ROW
                ) AS calendar_dates_updates_last_30_days
      FROM feed_guideline_index AS t1
      LEFT JOIN daily_improper_trip_updates AS t2
        ON t1.feed_key = t2.feed_key
      LEFT JOIN daily_improper_calendar_dates_updates AS t3
        ON t1.feed_key = t3.feed_key
),

int_gtfs_quality__lead_time AS (
    SELECT date,
           feed_key,
           {{ lead_time() }} AS check,
           {{ up_to_dateness() }} AS feature,
           CASE WHEN trip_updates_last_30_days + calendar_dates_updates_last_30_days > 0 THEN "FAIL"
                ELSE "PASS"
           END AS status
      FROM feed_update_count
)

SELECT * FROM int_gtfs_quality__lead_time
