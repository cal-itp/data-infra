WITH

idx AS (
    SELECT * FROM {{ ref('int_gtfs_quality__services_guideline_index') }}
),

services AS (
    SELECT *,
           manual_check__gtfs_schedule_data_ingested_in_trip_planner AS schedule_in_trip_planner
      FROM {{ ref('dim_services') }}
),

feed_listed_schedule AS (
    SELECT * FROM {{ ref('int_gtfs_quality__feed_listed_schedule') }}
),

int_gtfs_quality__trip_planner_schedule AS (
    SELECT
        idx.date,
        idx.service_key,
        {{ trip_planner_schedule() }} AS check,
        {{ compliance_schedule() }} AS feature,
        CASE
            WHEN schedule.status = 'FAIL' THEN {{ guidelines_na_check_status() }}
            WHEN schedule_in_trip_planner = 'Yes' THEN {{ guidelines_pass_status() }}
            WHEN schedule_in_trip_planner = 'No' THEN {{ guidelines_fail_status() }}
            WHEN schedule_in_trip_planner = 'N/A - no fixed-route service' THEN {{ guidelines_na_check_status() }}
            ELSE {{ guidelines_manual_check_needed_status() }}
        END AS status,
    FROM idx
    LEFT JOIN services
        ON idx.service_key = services.key
    LEFT JOIN feed_listed_schedule schedule
    ON idx.service_key = schedule.service_key
    AND idx.date = schedule.date
)

SELECT * FROM int_gtfs_quality__trip_planner_schedule
