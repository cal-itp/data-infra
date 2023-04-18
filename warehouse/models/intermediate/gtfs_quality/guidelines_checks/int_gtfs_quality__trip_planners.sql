WITH

idx AS (
    SELECT * FROM {{ ref('int_gtfs_quality__guideline_checks_index') }}
    WHERE check IN ({{ trip_planner_schedule() }}, {{ trip_planner_rt() }})
),

service_checks AS (
    SELECT
        key,
        source_record_id,
        manual_check__gtfs_schedule_data_ingested_in_trip_planner,
        manual_check__gtfs_realtime_data_ingested_in_trip_planner,
        _valid_from,
        _valid_to
    FROM {{ ref('dim_services') }}
),

check_start_schedule AS (
    SELECT
        CAST(MIN(_valid_from) AS DATETIME) AS first_check_date_schedule
    FROM service_checks
    WHERE manual_check__gtfs_schedule_data_ingested_in_trip_planner IS NOT NULL AND manual_check__gtfs_schedule_data_ingested_in_trip_planner != "Unknown"
),

check_start_rt AS (
    SELECT
        CAST(MIN(_valid_from) AS DATETIME) AS first_check_date_rt
    FROM service_checks
    WHERE manual_check__gtfs_realtime_data_ingested_in_trip_planner IS NOT NULL AND manual_check__gtfs_realtime_data_ingested_in_trip_planner != "Unknown"
),

int_gtfs_quality__trip_planners AS (
    SELECT
        idx.* EXCEPT(status),
        first_check_date_rt,
        first_check_date_schedule,
        manual_check__gtfs_schedule_data_ingested_in_trip_planner,
        manual_check__gtfs_realtime_data_ingested_in_trip_planner,
        CASE
            WHEN has_service AND has_schedule_url AND check = {{ trip_planner_schedule() }}
                THEN
                    CASE
                        WHEN manual_check__gtfs_schedule_data_ingested_in_trip_planner = 'Yes' THEN {{ guidelines_pass_status() }}
                        WHEN manual_check__gtfs_schedule_data_ingested_in_trip_planner = 'No' THEN {{ guidelines_fail_status() }}
                        WHEN manual_check__gtfs_schedule_data_ingested_in_trip_planner = 'N/A - no fixed-route service' THEN {{ guidelines_na_check_status() }}
                        WHEN date < first_check_date_schedule THEN {{ guidelines_na_too_early_status() }}
                        WHEN manual_check__gtfs_schedule_data_ingested_in_trip_planner IS NULL OR manual_check__gtfs_schedule_data_ingested_in_trip_planner = "Unknown" THEN {{ guidelines_manual_check_needed_status() }}
                    END
            WHEN has_service AND (has_rt_url_tu OR has_rt_url_vp) AND check = {{ trip_planner_rt() }}
                THEN
                    CASE
                        WHEN manual_check__gtfs_realtime_data_ingested_in_trip_planner = 'Yes' THEN {{ guidelines_pass_status() }}
                        WHEN manual_check__gtfs_realtime_data_ingested_in_trip_planner = 'No' THEN {{ guidelines_fail_status() }}
                        WHEN manual_check__gtfs_realtime_data_ingested_in_trip_planner = 'N/A - no fixed-route service' THEN {{ guidelines_na_check_status() }}
                        WHEN date < first_check_date_rt THEN {{ guidelines_na_too_early_status() }}
                        WHEN manual_check__gtfs_realtime_data_ingested_in_trip_planner IS NULL OR manual_check__gtfs_realtime_data_ingested_in_trip_planner = "Unknown" THEN {{ guidelines_manual_check_needed_status() }}
                    END
            -- only applicable when there's schedule, TU, or VP
            WHEN has_service THEN {{ guidelines_na_entity_status() }}
            ELSE idx.status
        END AS status,
    FROM idx
    CROSS JOIN check_start_schedule
    CROSS JOIN check_start_rt
    LEFT JOIN service_checks
        ON idx.service_key = service_checks.key
)

SELECT * FROM int_gtfs_quality__trip_planners
