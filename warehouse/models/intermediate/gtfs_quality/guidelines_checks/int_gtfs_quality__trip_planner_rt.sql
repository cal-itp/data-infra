WITH

idx AS (
    SELECT * FROM {{ ref('int_gtfs_quality__services_guideline_index') }}
),

feed_listed_vp AS (
    SELECT * FROM {{ ref('int_gtfs_quality__feed_listed_vp') }}
),

feed_listed_tu AS (
    SELECT * FROM {{ ref('int_gtfs_quality__feed_listed_tu') }}
),

services AS (
    SELECT *,
           manual_check__gtfs_realtime_data_ingested_in_trip_planner AS rt_in_trip_planner
      FROM {{ ref('dim_services') }}
),

int_gtfs_quality__trip_planner_rt AS (
    SELECT
        idx.date,
        idx.service_key,
        {{ trip_planner_rt() }} AS check,
        {{ compliance_rt() }} AS feature,
        CASE
            WHEN tu.status = 'FAIL' AND vp.status = 'FAIL' THEN {{ guidelines_na_check_status() }}
            WHEN rt_in_trip_planner = 'Yes' THEN {{ guidelines_pass_status() }}
            WHEN rt_in_trip_planner = 'No' THEN {{ guidelines_fail_status() }}
            WHEN rt_in_trip_planner = 'N/A - no fixed-route service' THEN {{ guidelines_na_check_status() }}
            ELSE {{ guidelines_manual_check_needed_status() }}
        END AS status,
    FROM idx
    LEFT JOIN services
    ON idx.service_key = services.key
    LEFT JOIN feed_listed_vp vp
    ON idx.service_key = vp.service_key
    AND idx.date = vp.date
    LEFT JOIN feed_listed_tu tu
    ON idx.service_key = tu.service_key
    AND idx.date = tu.date
)

SELECT * FROM int_gtfs_quality__trip_planner_rt
