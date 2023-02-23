WITH feed_guideline_index AS (
    SELECT * FROM {{ ref('int_gtfs_quality__schedule_feed_guideline_index') }}
),

dim_trips AS (
    SELECT * FROM {{ ref('dim_trips') }}
),

dim_stops AS (
    SELECT * FROM {{ ref('dim_stops') }}
),

feed_trips_summary AS (
   SELECT
       feed_key,
       COUNTIF(wheelchair_accessible IS NOT NULL AND CAST(wheelchair_accessible AS string) != "0") AS ct_trips_accessibility_info,
       COUNT(*) AS ct_trips
    FROM dim_trips
   GROUP BY feed_key
),

feed_stops_summary AS (
   SELECT
       feed_key,
       COUNTIF(wheelchair_boarding IS NOT NULL AND CAST(wheelchair_boarding AS string) != "0") AS ct_stops_accessibility_info,
       COUNT(*) AS ct_stops
    FROM dim_stops
   GROUP BY feed_key
),

int_gtfs_quality__complete_wheelchair_accessibility_data AS (
    SELECT
        t1.date,
        t1.feed_key,
        {{ complete_wheelchair_accessibility_data() }} AS check,
        {{ accurate_accessibility_data() }} AS feature,
        CASE
            WHEN t2.ct_trips_accessibility_info = t2.ct_trips AND t3.ct_stops_accessibility_info = t3.ct_stops THEN {{ guidelines_pass_status() }}
            ELSE {{ guidelines_fail_status() }}
        END AS status,
      FROM feed_guideline_index t1
      LEFT JOIN feed_trips_summary t2
             ON t1.feed_key = t2.feed_key
      LEFT JOIN feed_stops_summary t3
             ON t1.feed_key = t3.feed_key
)

SELECT * FROM int_gtfs_quality__complete_wheelchair_accessibility_data
