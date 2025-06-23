WITH guideline_index AS (
    SELECT *
    FROM {{ ref('int_gtfs_quality__guideline_checks_index') }}
    WHERE check = {{ wheelchair_boarding_stops() }}
),

dim_stops AS (
    SELECT * FROM {{ ref('dim_stops') }}
),

feed_stops_summary AS (
   SELECT
       feed_key,
       COUNTIF(wheelchair_boarding IS NOT NULL AND CAST(wheelchair_boarding AS STRING) != "0") AS ct_stops_accessibility_info,
       COUNT(*) AS ct_stops,
       ROUND(COUNTIF(wheelchair_boarding IS NOT NULL AND CAST(wheelchair_boarding AS STRING) != "0")/COUNT(*) *100) AS wheelchair_boarding_stops_percentage
    FROM dim_stops
   GROUP BY feed_key
),

check_start AS (
    SELECT MIN(_feed_valid_from) AS first_check_date
    FROM dim_stops
),

int_gtfs_quality__wheelchair_boarding_stops AS (
    SELECT
        idx.* EXCEPT(status),
        CASE
            WHEN has_schedule_feed
                THEN
                    CASE
                        WHEN stops.ct_stops_accessibility_info = stops.ct_stops
                             THEN {{ guidelines_pass_status() }}
                        WHEN CAST(idx.date AS TIMESTAMP) < first_check_date THEN {{ guidelines_na_too_early_status() }}
                        ELSE {{ guidelines_fail_status() }}
                    END
            ELSE idx.status
        END AS status,
        wheelchair_boarding_stops_percentage
    FROM guideline_index AS idx
    CROSS JOIN check_start
    LEFT JOIN feed_stops_summary AS stops
            ON idx.schedule_feed_key = stops.feed_key
)

SELECT * FROM int_gtfs_quality__wheelchair_boarding_stops
