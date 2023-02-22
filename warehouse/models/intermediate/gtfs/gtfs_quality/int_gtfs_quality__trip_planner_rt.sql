WITH

idx AS (
    SELECT * FROM {{ ref('int_gtfs_quality__services_guideline_index') }}
),

services AS (
    SELECT * FROM {{ ref('dim_services') }}
),

int_gtfs_quality__trip_planner_rt AS (
    SELECT
        idx.date,
        idx.service_key,
        {{ trip_planner_rt() }} AS check,
        {{ compliance_rt() }} AS feature,
        CASE manual_check__gtfs_realtime_data_ingested_in_trip_planner
            WHEN 'Yes' THEN {{ guidelines_pass_status() }}
            WHEN 'No' THEN {{ guidelines_fail_status() }}
            ELSE {{ guidelines_manual_check_needed_status() }}
        END AS status,
    FROM idx
    LEFT JOIN services
        ON idx.service_key = services.key
)

SELECT * FROM int_gtfs_quality__trip_planner_rt
