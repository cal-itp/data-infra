WITH guideline_index AS (
    SELECT *
    FROM {{ ref('int_gtfs_quality__guideline_checks_index') }}
    WHERE check = {{ fixed_routes_match() }}
),

gtfs_service_data AS (
    SELECT *
    FROM {{ ref('dim_gtfs_service_data') }}
),

-- TODO: technically ideally we would check specifically if there is a value available for a schedule-type record
-- rather than just checking across all records
check_start AS (
    SELECT MIN(_valid_from) AS first_check_date
    FROM gtfs_service_data
    WHERE manual_check__fixed_route_completeness IS NOT NULL AND manual_check__fixed_route_completeness != "Unknown"
),

int_gtfs_quality__fixed_routes_match AS (
    SELECT
        idx.* EXCEPT(status),
        manual_check__fixed_route_completeness,
        first_check_date,
        CASE
        -- check that the row has the right entity + check combo, then assign statuses
            WHEN idx.has_gtfs_service_data_schedule
                   THEN
                    CASE
                        WHEN manual_check__fixed_route_completeness = "Complete" THEN {{ guidelines_pass_status() }}
                        WHEN CAST(idx.date AS TIMESTAMP) < first_check_date THEN {{ guidelines_na_too_early_status() }}
                        WHEN manual_check__fixed_route_completeness = "Unknown"
                            OR manual_check__fixed_route_completeness IS NULL
                            OR manual_check__fixed_route_completeness = "To be checked in warehouse" THEN {{ guidelines_manual_check_needed_status() }}
                        WHEN manual_check__fixed_route_completeness = "Incomplete" THEN {{ guidelines_fail_status() }}
                    END
            ELSE idx.status
        END AS status,
      FROM guideline_index AS idx
      CROSS JOIN check_start
      LEFT JOIN gtfs_service_data
        ON idx.gtfs_service_data_key = gtfs_service_data.key
)

SELECT * FROM int_gtfs_quality__fixed_routes_match
