WITH guideline_index AS (
    SELECT *
    FROM {{ ref('int_gtfs_quality__guideline_checks_index') }}
    WHERE check = {{ complete_wheelchair_accessibility_data() }}
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
       COUNTIF(wheelchair_accessible IS NOT NULL AND CAST(wheelchair_accessible AS STRING) != "0") AS ct_trips_accessibility_info,
       COUNT(*) AS ct_trips
    FROM dim_trips
   GROUP BY feed_key
),

feed_stops_summary AS (
   SELECT
       feed_key,
       COUNTIF(wheelchair_boarding IS NOT NULL AND CAST(wheelchair_boarding AS STRING) != "0") AS ct_stops_accessibility_info,
       COUNT(*) AS ct_stops
    FROM dim_stops
   GROUP BY feed_key
),

check_start AS (
    SELECT MIN(_feed_valid_from) AS first_check_date
    FROM dim_trips
),

int_gtfs_quality__complete_wheelchair_accessibility_data AS (
    SELECT
        idx.* EXCEPT(status),
        CASE
            WHEN has_schedule_feed
                THEN
                    CASE
                        WHEN trips.ct_trips_accessibility_info = trips.ct_trips
                            AND stops.ct_stops_accessibility_info = stops.ct_stops
                            THEN {{ guidelines_pass_status() }}
                        -- TODO: we might be able to handle these if we wanted to shift to noon or similar -- only "too early" are on April 21, 2021 specifically
                        -- but impact is small (many checks not assessessed this far back) so probably not worth it right now
                        WHEN CAST(idx.date AS TIMESTAMP) < first_check_date THEN {{ guidelines_na_too_early_status() }}
                        ELSE {{ guidelines_fail_status() }}
                    END
            ELSE idx.status
        END AS status
    FROM guideline_index AS idx
    CROSS JOIN check_start
    LEFT JOIN feed_trips_summary AS trips
            ON idx.schedule_feed_key = trips.feed_key
    LEFT JOIN feed_stops_summary AS stops
            ON idx.schedule_feed_key = stops.feed_key
)

SELECT * FROM int_gtfs_quality__complete_wheelchair_accessibility_data
