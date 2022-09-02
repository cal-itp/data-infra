WITH feed_guideline_index AS (
    SELECT * FROM {{ ref('stg_gtfs_guidelines__feed_guideline_index') }}
    WHERE check = {{ complete_wheelchair_accessibility_data() }}
),

gtfs_schedule_index_feed_trip_stops AS (
    SELECT * FROM {{ ref('gtfs_schedule_index_feed_trip_stops') }}
),

gtfs_schedule_dim_feeds AS (
    SELECT * FROM {{ ref('gtfs_schedule_dim_feeds') }}
),

gtfs_schedule_dim_trips AS (
    SELECT * FROM {{ ref('gtfs_schedule_dim_trips') }}
),

gtfs_schedule_dim_stops AS (
    SELECT * FROM {{ ref('gtfs_schedule_dim_stops') }}
),

-- One row for every trip_key, mapping it to to its feed_key.
feed_trips AS (
    SELECT
        DISTINCT trip_key,
        feed_key
    FROM gtfs_schedule_index_feed_trip_stops
),

-- One row for every stop_key, mapping it to to its feed_key.
feed_stops AS (
    SELECT
        DISTINCT stop_key,
        feed_key
    FROM gtfs_schedule_index_feed_trip_stops
),

-- Counts use of wheelchair_accessible field in trips.txt for a given FEED (which spans multiple days)
feed_trips_aggregate AS (
    SELECT
        t1.feed_key,
        COUNT(CASE
                WHEN t2.wheelchair_accessible IS NOT NULL THEN 1
              END) AS accessibility_trips,
        COUNT(*) AS trips
    FROM feed_trips AS t1
    LEFT JOIN gtfs_schedule_dim_trips AS t2
      ON t1.trip_key = t2.trip_key
    GROUP BY t1.feed_key
),

-- Counts use of wheelchair_boarding field in stops.txt for a given FEED (which spans multiple days)
feed_stops_aggregate AS (
    SELECT
        t1.feed_key,
        COUNT(CASE
                WHEN t2.wheelchair_boarding IS NOT NULL THEN 1
              END) AS accessibility_stops,
        COUNT(*) AS stops
    FROM feed_stops AS t1
    LEFT JOIN gtfs_schedule_dim_stops AS t2
      ON t1.stop_key = t2.stop_key
   GROUP BY t1.feed_key
),

-- With one row per feed, combines trips and stops wheelchair checks
-- Also joins with dim_feeds, to get ITP-ID and extraction/deletion dates
feed_wheelchair_check AS (
    SELECT
        t3.calitp_itp_id,
        t3.calitp_url_number,
        t1.accessibility_trips,
        t1.trips,
        t2.accessibility_stops,
        t2.stops,
        {{ complete_wheelchair_accessibility_data() }} AS check,
        CASE
            WHEN t1.accessibility_trips = t1.trips AND t2.accessibility_stops = t2.stops THEN "PASS"
        ELSE "FAIL"
        END AS status,
        t3.calitp_extracted_at,
        t3.calitp_deleted_at
    FROM feed_trips_aggregate AS t1
    LEFT JOIN feed_stops_aggregate AS t2
      ON t1.feed_key = t2.feed_key
    LEFT JOIN gtfs_schedule_dim_feeds AS t3
      ON t1.feed_key = t3.feed_key
),

-- Joins our feed-level check with feed_guideline_index, where each feed will have a row for every day it is active
daily_wheelchair_check AS (
    SELECT
        t1.date,
        t1.calitp_itp_id,
        t1.calitp_url_number,
        t1.calitp_agency_name,
        t1.check,
        t1.feature,
        t2.status
    FROM feed_guideline_index AS t1
    LEFT JOIN feed_wheelchair_check AS t2
       ON t1.calitp_itp_id = t2.calitp_itp_id
      AND t1.calitp_url_number = t2.calitp_url_number
      AND t1.check = t2.check
      AND t1.date >= t2.calitp_extracted_at
      AND t1.date < t2.calitp_deleted_at
)

SELECT * FROM daily_wheelchair_check
