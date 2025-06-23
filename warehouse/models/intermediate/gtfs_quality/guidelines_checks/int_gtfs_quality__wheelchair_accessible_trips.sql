WITH guideline_index AS (
    SELECT *
    FROM {{ ref('int_gtfs_quality__guideline_checks_index') }}
    WHERE check = {{ wheelchair_accessible_trips() }}
),

dim_trips AS (
    SELECT * FROM {{ ref('dim_trips') }}
),

feed_trips_summary AS (
   SELECT
       feed_key,
       COUNTIF(wheelchair_accessible IS NOT NULL AND CAST(wheelchair_accessible AS STRING) != "0") AS ct_trips_accessibility_info,
       COUNT(*) AS ct_trips,
       ROUND(COUNTIF(wheelchair_accessible IS NOT NULL AND CAST(wheelchair_accessible AS STRING) != "0")/COUNT(*)*100) AS percentage
    FROM dim_trips
   GROUP BY feed_key
),

check_start AS (
    SELECT MIN(_feed_valid_from) AS first_check_date
    FROM dim_trips
),

int_gtfs_quality__wheelchair_accessible_trips AS (
    SELECT
        idx.* EXCEPT(status, percentage),
        CASE
            WHEN has_schedule_feed
                THEN
                    CASE
                        WHEN trips.ct_trips_accessibility_info = trips.ct_trips
                            THEN {{ guidelines_pass_status() }}
                        WHEN CAST(idx.date AS TIMESTAMP) < first_check_date THEN {{ guidelines_na_too_early_status() }}
                        ELSE {{ guidelines_fail_status() }}
                    END
            ELSE idx.status
        END AS status,
        trips.percentage
    FROM guideline_index AS idx
    CROSS JOIN check_start
    LEFT JOIN feed_trips_summary AS trips
            ON idx.schedule_feed_key = trips.feed_key
)

SELECT * FROM int_gtfs_quality__wheelchair_accessible_trips
